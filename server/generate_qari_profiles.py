# Add this to your lehja_module.py file, replacing the existing create_qari_profile method

def create_qari_profile(self, qari_name, audio_paths, save_path=None):
    """
    Create a profile for a specific Qari based on multiple audio samples.
    
    Args:
        qari_name: Name of the Qari (e.g., "Sheikh Abdul Basit")
        audio_paths: List of paths to audio files of this Qari's recitations
        save_path: Path to save the profile as JSON (optional)
        
    Returns:
        A dictionary containing the Qari's profile data
    """
    print(f"Creating profile for {qari_name} with {len(audio_paths)} audio samples")
    
    # Initialize profile structure
    profile = {
        "name": qari_name,
        "features": {
            "mfcc_means": [],
            "mfcc_stds": [],
            "chroma_means": [],
            "chroma_stds": [],
            "spectral_contrast_means": [],
            "spectral_contrast_stds": [],
            "tempo": [],
            "pitch_range": [],
            "complexity": []
        },
        "sample_count": 0,
        "created_at": self._get_timestamp()
    }
    
    # Process each audio file
    for i, audio_path in enumerate(audio_paths):
        try:
            print(f"Processing audio file {i+1}/{len(audio_paths)}: {os.path.basename(audio_path)}")
            # Load audio
            y, sr = self._load_audio(audio_path)
            
            # Skip very short audio segments (they cause problems)
            if len(y) < 2048:
                print(f"  Skipping {os.path.basename(audio_path)} - too short ({len(y)} samples)")
                continue
                
            # Extract features
            mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
            chroma = librosa.feature.chroma_stft(y=y, sr=sr)
            
            # Handle shorter audio files for spectral contrast
            n_fft = min(2048, len(y))
            if n_fft % 2 != 0:  # Make sure n_fft is even
                n_fft -= 1
                
            if n_fft < 16:  # Very short audio, skip it
                print(f"  Skipping {os.path.basename(audio_path)} - extremely short")
                continue
                
            contrast = librosa.feature.spectral_contrast(y=y, sr=sr, n_fft=n_fft)
            
            # Calculate mean and std for each feature
            profile["features"]["mfcc_means"].append(np.mean(mfcc, axis=1).tolist())
            profile["features"]["mfcc_stds"].append(np.std(mfcc, axis=1).tolist())
            profile["features"]["chroma_means"].append(np.mean(chroma, axis=1).tolist())
            profile["features"]["chroma_stds"].append(np.std(chroma, axis=1).tolist())
            profile["features"]["spectral_contrast_means"].append(np.mean(contrast, axis=1).tolist())
            profile["features"]["spectral_contrast_stds"].append(np.std(contrast, axis=1).tolist())
            
            # Extract global melodic features
            melody_features = self._extract_global_melody_features(y, sr)
            profile["features"]["tempo"].append(melody_features["tempo"])
            profile["features"]["pitch_range"].append(melody_features["pitch_range"])
            profile["features"]["complexity"].append(melody_features["complexity"])
            
            profile["sample_count"] += 1
            print(f"  Successfully processed audio sample {i+1}")
            
        except Exception as e:
            print(f"  Error processing audio file {audio_path}: {str(e)}")
            # Continue with next file
    
    # If no files were successfully processed, return empty profile
    if profile["sample_count"] == 0:
        print("No audio files could be processed. Profile creation failed.")
        return profile
        
    # Ensure we actually have features before trying to average
    if profile["sample_count"] > 0:
        # Calculate the final aggregated features
        avg_profile = {
            "name": qari_name,
            "features": {
                "mfcc_mean": np.mean(profile["features"]["mfcc_means"], axis=0).tolist(),
                "mfcc_std": np.mean(profile["features"]["mfcc_stds"], axis=0).tolist(),
                "chroma_mean": np.mean(profile["features"]["chroma_means"], axis=0).tolist(),
                "chroma_std": np.mean(profile["features"]["chroma_stds"], axis=0).tolist(),
                "spectral_contrast_mean": np.mean(profile["features"]["spectral_contrast_means"], axis=0).tolist(),
                "spectral_contrast_std": np.mean(profile["features"]["spectral_contrast_stds"], axis=0).tolist(),
                "tempo": np.mean(profile["features"]["tempo"]),
                "pitch_range": np.mean(profile["features"]["pitch_range"]),
                "complexity": np.mean(profile["features"]["complexity"])
            },
            "sample_count": profile["sample_count"],
            "created_at": profile["created_at"]
        }
    else:
        print("Warning: Not enough valid samples to create a proper profile.")
        avg_profile = profile
    
    # Save profile to file if path is provided
    if save_path:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(os.path.abspath(save_path)), exist_ok=True)
        
        with open(save_path, 'w', encoding='utf-8') as f:
            json.dump(avg_profile, f, ensure_ascii=False, indent=2)
            print(f"Profile saved to {save_path}")
    
    # Store in memory
    self.qari_profiles[qari_name] = avg_profile
    
    return avg_profile

# Add this helper method
def _get_timestamp(self):
    """Get the current timestamp in ISO format"""
    from datetime import datetime
    return datetime.now().isoformat()