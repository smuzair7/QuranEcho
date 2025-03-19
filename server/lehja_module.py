import numpy as np
import librosa
import torch
from transformers import AutoProcessor, AutoModelForSpeechSeq2Seq
from typing import Dict, List, Tuple
import json
import os
import re
import scipy
from scipy.spatial.distance import euclidean
from fastdtw import fastdtw
from dtaidistance import dtw

class LehjaModule:
    def __init__(self, model_path="tarteel-ai/whisper-base-ar-quran", sample_rate=16000):
        """
        Initialize the Lehja module for Quranic recitation style analysis.

        Args:
            model_path: Path to the Tarteel.ai whisper model
            sample_rate: Sample rate for audio processing (default: 16000 Hz)
        """
        self.processor = AutoProcessor.from_pretrained(model_path)
        self.model = AutoModelForSpeechSeq2Seq.from_pretrained(model_path)
        self.sample_rate = sample_rate
        self.qari_profiles = {}

    def transcribe_audio(self, audio_path: str) -> Dict:
        """
        Transcribe audio using Tarteel.ai's whisper model.
        Since we can't use word-level timestamps with this model,
        we'll segment the audio based on silence detection.

        Args:
            audio_path: Path to the audio file

        Returns:
            Dictionary containing transcription and approximate segments
        """
        # Load and preprocess audio
        audio, _ = librosa.load(audio_path, sr=self.sample_rate, mono=True)
        input_features = self.processor(
            audio,
            sampling_rate=self.sample_rate,
            return_tensors="pt"
        ).input_features

        # Generate transcription without timestamps
        with torch.no_grad():
            predicted_ids = self.model.generate(input_features)

        # Get transcription
        transcription = self.processor.batch_decode(
            predicted_ids,
            skip_special_tokens=True
        )[0]

        # Split text into words (considering Arabic text)
        words = re.findall(r'\S+', transcription)

        # Since we can't get timestamps from the model, we'll use silence detection
        # to create approximate segments
        # Detect non-silent intervals
        non_silent_intervals = librosa.effects.split(
            audio,
            top_db=20,  # Adjust this threshold as needed
            frame_length=512,
            hop_length=128
        )

        # If we have fewer intervals than words, fall back to dividing audio evenly
        if len(non_silent_intervals) < len(words):
            # Calculate total duration and segment duration
            total_duration = len(audio) / self.sample_rate
            segment_duration = total_duration / len(words)

            # Create word segments by dividing the audio evenly
            word_segments = []
            for i, word in enumerate(words):
                start_time = i * segment_duration
                end_time = (i + 1) * segment_duration

                word_segments.append({
                    "word": word,
                    "start_time": start_time,
                    "end_time": end_time
                })
        else:
            # If we have enough intervals, match them with words
            word_segments = []
            for i, word in enumerate(words):
                if i < len(non_silent_intervals):
                    start_sample, end_sample = non_silent_intervals[i]
                    word_segments.append({
                        "word": word,
                        "start_time": start_sample / self.sample_rate,
                        "end_time": end_sample / self.sample_rate
                    })
                else:
                    # If we run out of intervals, skip this word
                    continue

        return {
            "transcription": transcription,
            "segments": word_segments
        }
    def extract_melody_features(self, segment_audio, sr):
        """
        Extract detailed melodic features from an audio segment

        Args:
            segment_audio: Audio segment for a word
            sr: Sample rate

        Returns:
            Dictionary of melodic features
        """
        # Extract pitch contour using more refined technique
        if len(segment_audio) == 0:
            return {
                "pitch_mean": 0,
                "pitch_std": 0,
                "pitch_range": 0,
                "pitch_contour": [],
                "melodic_intervals": []
            }

        f0, voiced_flag, voiced_probs = librosa.pyin(
            segment_audio,
            fmin=librosa.note_to_hz('C2'),
            fmax=librosa.note_to_hz('C7'),
            sr=sr,
            frame_length=512,
            hop_length=256
        )

        # Remove NaN values (unvoiced segments)
        f0_clean = f0[~np.isnan(f0)] if f0 is not None else np.array([])

        if len(f0_clean) == 0:
            return {
                "pitch_mean": 0,
                "pitch_std": 0,
                "pitch_range": 0,
                "pitch_contour": [],
                "melodic_intervals": []
            }

        # Normalize and store the pitch contour (downsampled for efficiency)
        contour_length = min(len(f0_clean), 50)  # Limit length
        pitch_contour = librosa.resample(f0_clean, orig_sr=len(f0_clean), target_sr=contour_length).tolist()

        # Calculate melodic intervals (changes between consecutive pitches)
        melodic_intervals = np.diff(f0_clean).tolist() if len(f0_clean) > 1 else []

        return {
            "pitch_mean": float(np.mean(f0_clean)),
            "pitch_std": float(np.std(f0_clean)),
            "pitch_range": float(np.ptp(f0_clean)),  # peak-to-peak range
            "pitch_contour": pitch_contour,
            "melodic_intervals": melodic_intervals
        }
    def detect_maqam_features(self, segment_audio, sr):
        """
        Detect approximate maqam characteristics from audio segment

        Args:
            segment_audio: Audio segment for a word
            sr: Sample rate

        Returns:
            Dictionary of maqam/scale features
        """
        if len(segment_audio) < sr // 4:  # At least 0.25 seconds of audio
            return {
                "dominant_note": 0,
                "secondary_note": 0,
                "note_distribution": [0] * 12,
                "intervals": {
                    "minor_second": 0,
                    "major_second": 0,
                    "minor_third": 0,
                    "major_third": 0
                }
            }

        # Extract chroma features (pitch class profile)
        chroma = librosa.feature.chroma_cqt(y=segment_audio, sr=sr)

        # Get distribution of notes
        chroma_dist = np.mean(chroma, axis=1)

        # Identify dominant and secondary notes
        dominant_note_idx = np.argmax(chroma_dist)
        chroma_dist_copy = chroma_dist.copy()
        chroma_dist_copy[dominant_note_idx] = 0  # Remove dominant to find secondary
        secondary_note_idx = np.argmax(chroma_dist_copy)

        # Calculate intervals presence
        intervals = {
            "minor_second": float(np.mean(chroma_dist[(dominant_note_idx+1) % 12])),
            "major_second": float(np.mean(chroma_dist[(dominant_note_idx+2) % 12])),
            "minor_third": float(np.mean(chroma_dist[(dominant_note_idx+3) % 12])),
            "major_third": float(np.mean(chroma_dist[(dominant_note_idx+4) % 12]))
        }

        return {
            "dominant_note": int(dominant_note_idx),
            "secondary_note": int(secondary_note_idx),
            "note_distribution": chroma_dist.tolist(),
            "intervals": intervals
        }
    def detect_ornamentations(self, segment_audio, sr):
        """
        Detect Quranic melodic ornamentations

        Args:
            segment_audio: Audio segment for a word
            sr: Sample rate

        Returns:
            Dictionary of ornamentation features
        """
        if len(segment_audio) < sr // 4:  # At least 0.25 seconds of audio
            return {
                "spectral_contrast_mean": 0,
                "onset_strength_mean": 0,
                "tempo": 0,
                "energy_variation": 0
            }

        # Spectral contrast for timbral variations
        contrast = librosa.feature.spectral_contrast(y=segment_audio, sr=sr)

        # Onset strength for detecting syllable boundaries and emphasis
        onset_env = librosa.onset.onset_strength(y=segment_audio, sr=sr)

        # Tempo estimation - use try/except as it might fail on very short segments
        try:
            tempo = librosa.beat.tempo(onset_envelope=onset_env, sr=sr)[0]
        except:
            tempo = 0

        # Energy variation can indicate ornamentations
        rms = librosa.feature.rms(y=segment_audio)[0]
        energy_var = np.var(rms) if len(rms) > 0 else 0

        return {
            "spectral_contrast_mean": float(np.mean(contrast)) if contrast.size > 0 else 0,
            "onset_strength_mean": float(np.mean(onset_env)) if onset_env.size > 0 else 0,
            "tempo": float(tempo),
            "energy_variation": float(energy_var)
        }
    def extract_audio_features(self, audio_path: str, word_segments: List[Dict]) -> Dict:
        """
        Extract acoustic features for each word segment in the audio.

        Args:
            audio_path: Path to the audio file
            word_segments: List of dictionaries with word timing information

        Returns:
            Dictionary of features for each word segment
        """
        # Load audio
        y, _ = librosa.load(audio_path, sr=self.sample_rate, mono=True)

        word_features = {}

        for segment in word_segments:
            word = segment["word"]
            start_time = segment["start_time"]
            end_time = segment["end_time"]

            # Convert times to samples
            start_sample = int(start_time * self.sample_rate)
            end_sample = int(end_time * self.sample_rate)

            # Extract segment
            segment_audio = y[start_sample:end_sample]

            if len(segment_audio) == 0:
                continue

            # Extract features
            features = {}

            # 1. MFCCs - capture tonal quality
            mfccs = librosa.feature.mfcc(y=segment_audio, sr=self.sample_rate, n_mfcc=13)
            features["mfcc_mean"] = np.mean(mfccs, axis=1).tolist()
            features["mfcc_std"] = np.std(mfccs, axis=1).tolist()

            # 2. Energy/amplitude - capture emphasis
            features["energy_mean"] = float(np.mean(np.abs(segment_audio)))
            features["energy_std"] = float(np.std(np.abs(segment_audio)))

            # 3. Duration
            features["duration"] = float(end_time - start_time)

            # 4. NEW: Extract melodic features
            melody_features = self.extract_melody_features(segment_audio, self.sample_rate)
            features.update(melody_features)

            # 5. NEW: Extract maqam/scale features
            maqam_features = self.detect_maqam_features(segment_audio, self.sample_rate)
            features.update(maqam_features)

            # 6. NEW: Extract ornamentation features
            ornament_features = self.detect_ornamentations(segment_audio, self.sample_rate)
            features.update(ornament_features)

            # Store features for this word
            word_features[word] = features

        return word_features
    def analyze_full_recitation_melody(self, audio_path):
        """
        Analyze the melodic characteristics of the full recitation

        Args:
            audio_path: Path to the audio file

        Returns:
            Dictionary of global melodic features
        """
        # Load audio
        y, sr = librosa.load(audio_path, sr=self.sample_rate, mono=True)

        # Extract global tempo
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        tempo = librosa.beat.tempo(onset_envelope=onset_env, sr=sr)[0]

        # Analyze pitch trajectory across the entire recording
        f0, voiced_flag, voiced_probs = librosa.pyin(
            y, fmin=librosa.note_to_hz('C2'), fmax=librosa.note_to_hz('C7'), sr=sr
        )
        f0_clean = f0[~np.isnan(f0)] if f0 is not None else np.array([])

        # Default values if no pitch data
        pitch_data = {
            "pitch_range": 0,
            "mean_pitch": 0,
            "pitch_variation": 0,
            "full_pitch_contour": []
        }

        # Downsample pitch contour for manageable size
        if len(f0_clean) > 0:
            full_contour = librosa.resample(f0_clean, orig_sr=len(f0_clean), target_sr=100)
            pitch_data = {
                "pitch_range": float(np.ptp(f0_clean)),
                "mean_pitch": float(np.mean(f0_clean)),
                "pitch_variation": float(np.std(f0_clean)),
                "full_pitch_contour": full_contour.tolist()
            }

        # Detect modulations by analyzing changes in chroma features
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)

        # Create segments and detect if the dominant note changes
        num_segments = 10
        segment_length = chroma.shape[1] // num_segments
        modulations = []

        prev_dominant = None
        for i in range(num_segments):
            if i * segment_length >= chroma.shape[1]:
                break

            segment = chroma[:, i * segment_length:(i+1) * segment_length]
            if segment.size > 0:
                dominant = np.argmax(np.mean(segment, axis=1))
                if prev_dominant is not None and dominant != prev_dominant:
                    modulations.append(i / num_segments)  # Relative position
                prev_dominant = dominant

        # Calculate melodic complexity using entropy of pitch classes
        pitch_entropy = 0
        if chroma.size > 0:
            chroma_mean = np.mean(chroma, axis=1)
            if np.sum(chroma_mean) > 0:
                pitch_entropy = float(scipy.stats.entropy(chroma_mean + 1e-10))  # Add small value to avoid log(0)

        return {
            "overall_tempo": float(tempo),
            **pitch_data,
            "modulation_points": modulations,
            "melodic_complexity": pitch_entropy
        }
    def create_qari_profile(self, qari_name: str, audio_paths: List[str], save_path: str = None):
        """
        Create a profile for a specific Qari based on multiple recordings.

        Args:
            qari_name: Name of the Qari
            audio_paths: List of paths to the Qari's recitation audio files
            save_path: Path to save the profile (optional)
        """
        all_word_features = {}
        global_melody_features = []

        for audio_path in audio_paths:
            # Transcribe audio and get word timings
            transcription = self.transcribe_audio(audio_path)

            # Extract features for each word segment
            word_features = self.extract_audio_features(audio_path, transcription["segments"])

            # NEW: Analyze overall melodic characteristics
            full_melody = self.analyze_full_recitation_melody(audio_path)
            global_melody_features.append(full_melody)

            # Track word occurrences
            word_count = {}

            # Aggregate features across recordings
            for segment in transcription["segments"]:
                word = segment["word"]

                # Update word count for this word
                if word not in word_count:
                    word_count[word] = 1
                else:
                    word_count[word] += 1

                # Create a unique identifier for the word
                word_id = f"{word}_{word_count[word]}"

                # Get features for this word
                features = word_features.get(word, {})

                if word_id not in all_word_features:
                    all_word_features[word_id] = []

                all_word_features[word_id].append(features)

        # Average features across recordings
        average_features = {}
        for word_id, feature_list in all_word_features.items():
            if not feature_list:
                continue

            # Initialize with structure of first item
            avg = {}
            for key in feature_list[0].keys():
                # Handle list and non-list features differently
                if isinstance(feature_list[0][key], list):
                    # For arrays like MFCCs
                    arrays = [np.array(item[key]) for item in feature_list]
                    avg[key] = np.mean(arrays, axis=0).tolist()
                elif isinstance(feature_list[0][key], dict):
                    # For nested dictionaries like intervals
                    avg[key] = {}
                    for sub_key in feature_list[0][key].keys():
                        values = [item[key][sub_key] for item in feature_list]
                        avg[key][sub_key] = sum(values) / len(values)
                else:
                    # For scalar values
                    values = [item[key] for item in feature_list]
                    avg[key] = sum(values) / len(values)

            average_features[word_id] = avg

        # Average global melody features
        avg_global_melody = {}
        if global_melody_features:
            for key in global_melody_features[0].keys():
                if key == "full_pitch_contour":
                    # For pitch contour, use the most representative one
                    # (closest to the mean length)
                    lengths = [len(gm[key]) for gm in global_melody_features]
                    mean_length = sum(lengths) / len(lengths)
                    closest_idx = min(range(len(lengths)), key=lambda i: abs(lengths[i] - mean_length))
                    avg_global_melody[key] = global_melody_features[closest_idx][key]
                elif key == "modulation_points":
                    # Combine all modulation points
                    all_points = []
                    for gm in global_melody_features:
                        all_points.extend(gm[key])
                    avg_global_melody[key] = sorted(all_points)
                else:
                    # For scalar values
                    avg_global_melody[key] = sum(gm[key] for gm in global_melody_features) / len(global_melody_features)

        # Create the profile
        profile = {
            "qari_name": qari_name,
            "word_features": average_features,
            "global_melody": avg_global_melody
        }

        # Store in memory
        self.qari_profiles[qari_name] = profile

        # Save to disk if path provided
        if save_path:
            os.makedirs(os.path.dirname(save_path), exist_ok=True)
            with open(save_path, 'w', encoding='utf-8') as f:
                json.dump(profile, f, ensure_ascii=False, indent=2)

        return profile
    def compare_melody_similarity(self, user_features, qari_features):
        """
        Compare melodic features between user and qari focusing on pitch patterns rather than absolute values
        """
        # Basic pitch statistics similarity
        pitch_stats_sim = 1.0
        if user_features.get("pitch_mean", 0) != 0 and qari_features.get("pitch_mean", 0) != 0:
            pitch_stats_sim = 1.0 - min(1.0, (
                abs(user_features["pitch_mean"] - qari_features["pitch_mean"]) /
                max(qari_features["pitch_mean"], 0.001)
            ))

        # Pitch contour similarity (if available)
        # Convert pitch contours to relative changes (patterns)
        def get_pitch_pattern(contour):
            if len(contour) < 2:
                return []
            # Calculate relative changes (up/down pattern)
            pattern = np.diff(contour)
            # Normalize to get just the direction (-1 for down, 1 for up, 0 for same)
            pattern = np.sign(pattern)
            return pattern

        # Pitch pattern similarity
        contour_sim = 0.0
        if (len(user_features.get("pitch_contour", [])) > 0 and
            len(qari_features.get("pitch_contour", [])) > 0):

            # Get patterns of pitch movement
            user_pattern = get_pitch_pattern(user_features["pitch_contour"])
            qari_pattern = get_pitch_pattern(qari_features["pitch_contour"])

            if len(user_pattern) > 0 and len(qari_pattern) > 0:
                try:
                    # Ensure the pitch patterns are 1-D numpy arrays
                    user_pattern = np.array(user_pattern, dtype=np.float64).flatten()
                    qari_pattern = np.array(qari_pattern, dtype=np.float64).flatten()

                    # Debug: Print shape and type of pitch patterns
                    print("User Pitch Pattern Shape:", user_pattern.shape)
                    print("Qari Pitch Pattern Shape:", qari_pattern.shape)
                    print("User Pitch Pattern Type:", type(user_pattern))
                    print("Qari Pitch Pattern Type:", type(qari_pattern))

                    # Use DTW to compare patterns
                    distance = dtw.distance(user_pattern, qari_pattern)
                    # Convert distance to similarity
                    max_possible_dist = len(user_pattern)  # Maximum possible difference
                    contour_sim = 1.0 - min(1.0, distance / max_possible_dist)
                except Exception as e:
                    print(f"Error in DTW calculation: {e}")
                    contour_sim = 0.5

        # Adjust weights to focus more on pattern
        weights = {
            "pitch_stats": 0.1,    # Reduced weight for absolute pitch
            "contour": 0.5,        # Increased weight for pattern
            "maqam": 0.25,
            "ornaments": 0.15
        }

        # Maqam/scale similarity
        maqam_sim = 0.0
        if ("note_distribution" in user_features and "note_distribution" in qari_features):
            u_dist = np.array(user_features["note_distribution"])
            q_dist = np.array(qari_features["note_distribution"])

            # Use cosine similarity for note distributions
            if np.sum(u_dist) > 0 and np.sum(q_dist) > 0:
                maqam_sim = np.dot(u_dist, q_dist) / (np.linalg.norm(u_dist) * np.linalg.norm(q_dist))
                maqam_sim = max(0.0, min(1.0, maqam_sim))  # Ensure it's in [0,1]

        # Ornamentations similarity
        ornament_sim = 0.0
        if "energy_variation" in user_features and "energy_variation" in qari_features:
            if qari_features["energy_variation"] > 0:
                ornament_sim = 1.0 - min(1.0, abs(
                    user_features["energy_variation"] - qari_features["energy_variation"]
                ) / max(qari_features["energy_variation"], 0.001))

        # Weight and combine the different aspects of melody
        melody_similarity = (
            weights["pitch_stats"] * pitch_stats_sim +
            weights["contour"] * contour_sim +
            weights["maqam"] * maqam_sim +
            weights["ornaments"] * ornament_sim
        )

        # Clip to valid range
        melody_similarity = max(0.0, min(1.0, melody_similarity))

        return {
            "melody_similarity": melody_similarity,
            "pitch_similarity": pitch_stats_sim,
            "contour_similarity": contour_sim,
            "maqam_similarity": maqam_sim,
            "ornamentation_similarity": ornament_sim
        }

    def compare_global_melody(self, user_global, qari_global):
        """
        Compare global melodic features between user and qari.
        """
        # Tempo similarity (unchanged)
        tempo_sim = 1.0 - min(1.0, abs(
            user_global["overall_tempo"] - qari_global["overall_tempo"]
        ) / max(qari_global["overall_tempo"], 0.001))

        # NEW: Pitch range pattern similarity
        range_sim = 0.0
        if ("full_pitch_contour" in user_global and "full_pitch_contour" in qari_global and
            len(user_global["full_pitch_contour"]) > 0 and len(qari_global["full_pitch_contour"]) > 0):

            # Get normalized contours (scale to 0-1 range)
            def normalize_contour(contour):
                min_val = min(contour)
                max_val = max(contour)
                range_val = max_val - min_val if max_val > min_val else 1
                return [(x - min_val) / range_val for x in contour]

            user_contour = normalize_contour(user_global["full_pitch_contour"])
            qari_contour = normalize_contour(qari_global["full_pitch_contour"])

            # Debug: Print pitch contours
            print("User Pitch Contour:", user_contour)
            print("Qari Pitch Contour:", qari_contour)

            # Ensure the pitch contours are 1-D numpy arrays
            user_contour = np.array(user_contour, dtype=np.float64).flatten()
            qari_contour = np.array(qari_contour, dtype=np.float64).flatten()

            # Debug: Print shape and type of pitch contours
            print("User Pitch Contour Shape:", user_contour.shape)
            print("Qari Pitch Contour Shape:", qari_contour.shape)
            print("User Pitch Contour Type:", type(user_contour))
            print("Qari Pitch Contour Type:", type(qari_contour))

            # Compare the normalized patterns using DTW
            try:
                # Ensure inputs are 1-D arrays
                if user_contour.ndim == 1 and qari_contour.ndim == 1:
                    distance = dtw.distance(user_contour, qari_contour)
                    max_possible_dist = len(user_contour)

                    # Debug: Print DTW distance and max possible distance
                    print("DTW Distance:", distance)
                    print("Max Possible Distance:", max_possible_dist)

                    range_sim = 1.0 - min(1.0, distance / max_possible_dist)
                else:
                    print("Error: Pitch contours are not 1-D.")
                    range_sim = 0.5  # Default similarity in case of error
            except Exception as e:
                print(f"Error in DTW calculation: {e}")
                range_sim = 0.5  # Default similarity in case of error

        # Debug: Print pitch range similarity
        print("Pitch Range Similarity:", range_sim)

        # Rest of the method remains the same
        complexity_sim = 1.0 - min(1.0, abs(
            user_global["melodic_complexity"] - qari_global["melodic_complexity"]
        ) / max(qari_global["melodic_complexity"], 0.001))

        weights = {
            "tempo": 0.3,
            "range": 0.4,
            "complexity": 0.3
        }

        global_melody_sim = (
            weights["tempo"] * tempo_sim +
            weights["range"] * range_sim +
            weights["complexity"] * complexity_sim
        )

        return {
            "global_melody_similarity": global_melody_sim,
            "tempo_similarity": tempo_sim,
            "pitch_range_similarity": range_sim,
            "complexity_similarity": complexity_sim
        }
    def _generate_melody_feedback(self, word, melody_sim):
        """
        Generate feedback on melodic aspects of recitation

        Args:
            word: The word being compared
            melody_sim: Dictionary of melodic similarity scores

        Returns:
            List of feedback strings
        """
        feedback = []

        if melody_sim["melody_similarity"] < 0.7:
            if melody_sim["pitch_similarity"] < 0.6:
                feedback.append(f"When reciting '{word}', try to adjust your pitch to better match the Qari's tone.")

            if melody_sim["contour_similarity"] < 0.6:
                feedback.append(f"The melodic shape of '{word}' differs from the Qari. Try following their pitch pattern more closely.")

            if melody_sim["maqam_similarity"] < 0.6:
                feedback.append(f"Your musical mode when reciting '{word}' differs from the Qari's style.")

            if melody_sim["ornamentation_similarity"] < 0.6:
                feedback.append(f"Try to match the Qari's ornamental style when reciting '{word}'.")

        return feedback
    def _generate_global_melody_feedback(self, global_sim):
        """
        Generate feedback on global melodic aspects of recitation

        Args:
            global_sim: Dictionary of global melody similarity scores

        Returns:
            List of feedback strings
        """
        feedback = []

        if global_sim["global_melody_similarity"] < 0.7:
            if global_sim["tempo_similarity"] < 0.6:
                feedback.append("Try to adjust your overall recitation speed to better match the Qari's tempo.")

            if global_sim["pitch_range_similarity"] < 0.6:
                feedback.append("Your pitch range differs from the Qari's style. Try to expand or contract your melodic range accordingly.")

            if global_sim["complexity_similarity"] < 0.6:
                if global_sim["complexity_similarity"] < 0.3:
                    feedback.append("Your recitation is considerably less melodically complex than the Qari's. Try adding more melodic variation.")
                else:
                    feedback.append("Your melodic style differs from the Qari's in complexity. Try to match their level of melodic variation.")

        return feedback

    def visualize_comparison(self, user_audio: str, qari_audio: str) -> Dict:
        """Generate visualization of recitation comparison"""
        import matplotlib.pyplot as plt

        # Load audio files
        user_y, _ = librosa.load(user_audio, sr=self.sample_rate)
        qari_y, _ = librosa.load(qari_audio, sr=self.sample_rate)

        # Generate spectrograms
        user_spec = librosa.feature.melspectrogram(y=user_y, sr=self.sample_rate)
        qari_spec = librosa.feature.melspectrogram(y=qari_y, sr=self.sample_rate)

        # Plot comparison
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
        librosa.display.specshow(librosa.power_to_db(user_spec), y_axis='mel', x_axis='time', ax=ax1)
        librosa.display.specshow(librosa.power_to_db(qari_spec), y_axis='mel', x_axis='time', ax=ax2)

        ax1.set_title('User Recitation')
        ax2.set_title('Qari Recitation')
        plt.tight_layout()

        return fig

    def generate_detailed_feedback(self, comparison_results: Dict) -> Dict:
        """Generate detailed, word-level feedback with timestamps"""
        feedback = {
            "overall": [],
            "word_level": [],
            "timing": [],
            "melody": []
        }

        for word, details in comparison_results["word_comparisons"].items():
            if details["overall"] < 0.6:
                timestamp = f"{details.get('start_time', 0):.2f}s"
                if details["details"]["melody_similarity"] < 0.5:
                    feedback["melody"].append({
                        "word": word,
                        "time": timestamp,
                        "message": f"Melodic pattern differs at {word}"
                    })
                if details["details"]["duration"] < 0.5:
                    feedback["timing"].append({
                        "word": word,
                        "time": timestamp,
                        "message": f"Adjust timing for {word}"
                    })

        return feedback

    def compare_recitation(self, audio_path: str, qari_name: str) -> Dict:
        """
        Compare a user's recitation with a specific Qari's style.

        Args:
            audio_path: Path to the user's audio recording
            qari_name: Name of the Qari to compare with

        Returns:
            Dictionary with similarity scores and feedback
        """
        if qari_name not in self.qari_profiles:
            raise ValueError(f"Profile for Qari '{qari_name}' not found")

        # Get Qari's profile
        qari_profile = self.qari_profiles[qari_name]

        # Transcribe user audio and get word timings
        user_transcription = self.transcribe_audio(audio_path)

        # Extract features for user recording
        user_features = self.extract_audio_features(audio_path, user_transcription["segments"])

        # NEW: Extract global melody features for user recording
        user_global_melody = self.analyze_full_recitation_melody(audio_path)

        # Compare word by word
        comparison_results = {}
        overall_similarity = []
        overall_melody_similarity = []
        feedback = []

        # Track word occurrences for the user's recitation
        user_word_count = {}

        for word_segment in user_transcription["segments"]:
            word = word_segment["word"]

            # Update word count for this word in the user's recitation
            if word not in user_word_count:
                user_word_count[word] = 1
            else:
                user_word_count[word] += 1

            # Create the unique identifier for the Qari's profile
            qari_word_id = f"{word}_{user_word_count[word]}"

            # Skip if word not in reference
            if qari_word_id not in qari_profile["word_features"]:
                continue

            # Skip if word not in user features
            if word not in user_features:
                continue

            user_word_features = user_features[word]
            qari_word_features = qari_profile["word_features"][qari_word_id]

            # Calculate original similarity scores
            original_similarity = {
                "mfcc": 1.0 - np.mean(np.abs(np.array(user_word_features["mfcc_mean"]) -
                                            np.array(qari_word_features["mfcc_mean"]))) /
                        max(np.mean(np.abs(np.array(qari_word_features["mfcc_mean"]))), 0.001),

                "energy": 1.0 - abs(user_word_features["energy_mean"] - qari_word_features["energy_mean"]) /
                        max(abs(qari_word_features["energy_mean"]), 0.001),

                "duration": 1.0 - abs(user_word_features["duration"] - qari_word_features["duration"]) /
                            max(abs(qari_word_features["duration"]), 0.001)
            }

            # NEW: Calculate melodic similarity
            melody_similarity = self.compare_melody_similarity(user_word_features, qari_word_features)

            # Clip values to [0, 1] range
            for key in original_similarity:
                original_similarity[key] = max(0.0, min(1.0, original_similarity[key]))

            # Combine original and melodic similarity
            combined_similarity = {**original_similarity, **melody_similarity}

            # Calculate overall similarity with new weights
            weights = {
                "mfcc": 0.15,      # Reduced weight for pronunciation
                "energy": 0.3,     # Reduced weight for emphasis
                "duration": 0.3,   # Reduced weight for rhythm
                "melody_similarity": 0.25  # High weight for melodic aspects
            }

            word_similarity = (
                weights["mfcc"] * original_similarity["mfcc"] +
                weights["energy"] * original_similarity["energy"] +
                weights["duration"] * original_similarity["duration"] +
                weights["melody_similarity"] * melody_similarity["melody_similarity"]
            )

            overall_similarity.append(word_similarity)
            overall_melody_similarity.append(melody_similarity["melody_similarity"])

            comparison_results[word] = {
                "overall": word_similarity,
                "details": combined_similarity
            }

            # Generate feedback for this word
            if word_similarity < 0.5:
                if melody_similarity["melody_similarity"] < 0.4:
                    feedback.append(f"The melodic pattern for '{word}' differs significantly from Sheikh {qari_name}'s style.")
                if original_similarity["duration"] < 0.4:
                    feedback.append(f"Try adjusting the duration of '{word}' to match Sheikh {qari_name}'s timing.")
                if original_similarity["mfcc"] < 0.4:
                    feedback.append(f"The pronunciation of '{word}' could be improved to match Sheikh {qari_name}'s style.")

        # Calculate overall scores
        avg_similarity = sum(overall_similarity) / max(len(overall_similarity), 1)
        avg_melody_similarity = sum(overall_melody_similarity) / max(len(overall_melody_similarity), 1)

        # NEW: Compare global melody patterns
        global_melody_result = self.compare_global_melody(user_global_melody, qari_profile["global_melody"])

        # Extract the global melody similarity score (assuming it returns a value between 0 and 1)
        # If compare_global_melody returns a dictionary, extract the main similarity score
        if isinstance(global_melody_result, dict):
            global_melody_similarity = global_melody_result.get("global_melody_similarity", 0.5)  # Default to 0.5 if not found
        else:
            # If it's already a float value
            global_melody_similarity = global_melody_result

        # Combine word-level and global melody similarity
        final_similarity = 0.5 * avg_similarity + 0.5 * global_melody_similarity

        # Generate overall feedback
        if len(feedback) == 0:
            if final_similarity > 0.8:
                feedback.append(f"Excellent recitation! Your style closely matches Sheikh {qari_name}'s melodic pattern.")
            elif final_similarity > 0.6:
                feedback.append(f"Good recitation with strong elements of Sheikh {qari_name}'s style. Focus on matching the melodic flow more closely.")
            else:
                feedback.append(f"Your recitation has some similarities to Sheikh {qari_name}'s style. Try listening closely to his melodic patterns and rhythm.")

        return {
            "overall_similarity": final_similarity,
            "melodic_similarity": avg_melody_similarity,
            "global_melody_analysis": global_melody_result,  # Include the full analysis
            "word_comparisons": comparison_results,
            "feedback": feedback
        }
    def _generate_global_melody_feedback(self, global_sim):
        """
        Generate feedback on global melodic aspects of recitation.
        """
        feedback = []

        if global_sim["global_melody_similarity"] < 0.7:
            if global_sim["tempo_similarity"] < 0.6:
                feedback.append("Try to adjust your overall recitation speed to better match the Qari's tempo.")

            if global_sim["pitch_range_similarity"] < 0.6:
                feedback.append("Your pitch range differs from the Qari's style. Try to expand or contract your melodic range accordingly.")

            if global_sim["complexity_similarity"] < 0.6:
                if global_sim["complexity_similarity"] < 0.3:
                    feedback.append("Your recitation is considerably less melodically complex than the Qari's. Try adding more melodic variation.")
                else:
                    feedback.append("Your melodic style differs from the Qari's in complexity. Try to match their level of melodic variation.")

        return feedback