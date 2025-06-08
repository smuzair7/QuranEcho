import os
import numpy as np
import tensorflow as tf
import librosa
import tempfile
import traceback
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import warnings
import json
warnings.filterwarnings('ignore')

app = Flask(__name__)

# Define the correct harf mappings based on the dataset folders
# Updated with correct mappings based on the model's training order
id_to_harf = {
    0: 'Aain',   # ع
    1: 'Alif',   # ا
    2: 'Ba',     # ب
    3: 'Dal',    # د
    4: 'Duad',   # ض
    5: 'Faa',    # ف
    6: 'Ghain',  # غ
    7: 'Haa',    # ه
    8: 'Hha',    # ح
    9: 'Jeem',   # ج
    10: 'Kaif',  # ك
    11: 'Kha',   # خ
    12: 'Laam',  # ل
    13: 'Meem',  # م
    14: 'Noon',  # ن
    15: 'Qauf',  # ق
    16: 'Raa',   # ر
    17: 'Sa',    # ث - This is Sa (Thaa with 3 dots)
    18: 'Saud',  # ص
    19: 'Seen',  # س - This is Seen
    20: 'Sheen', # ش
    21: 'Ta',    # ت
    22: 'Tua',   # ط
    23: 'Wao',   # و
    24: 'Yaa',   # ي
    25: 'Zaa',   # ز
    26: 'Zhal',  # ذ
    27: 'Zua'    # ظ
}

# Create inverse mapping
harf_to_id = {harf: idx for idx, harf in id_to_harf.items()}

# Path to the TFLite model
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'model', 'fine_tuned_model_float32.tflite')

# Load TFLite model
interpreter = None

def load_model():
    global interpreter
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print(f"Model loaded successfully with {len(id_to_harf)} output classes")
    return input_details, output_details

input_details, output_details = load_model()

# Audio preprocessing function (exactly matching training)
def preprocess_audio(file_path):
    # Load audio
    audio, sr = librosa.load(file_path, sr=44100)
    
    # Noise reduction
    audio = librosa.effects.preemphasis(audio, coef=0.97)
    
    # Silence removal
    audio, _ = librosa.effects.trim(audio, top_db=25)
    
    # Generate mel-spectrogram
    mel = librosa.feature.melspectrogram(
        y=audio, sr=sr,
        n_mels=128, n_fft=2048, hop_length=441
    )
    mel_db = librosa.power_to_db(mel, ref=np.max)
    
    # Resize to model input shape
    mel_resized = tf.image.resize(mel_db[..., np.newaxis], (227, 227))
    return mel_resized.numpy()

def predict_harf(audio_file):
    # Preprocess the audio
    mel = preprocess_audio(audio_file)
    
    # Ensure input shape matches the model's expected input
    input_data = mel[np.newaxis, ...].astype(np.float32)
    
    # Set input tensor
    interpreter.set_tensor(input_details[0]['index'], input_data)
    
    # Run inference
    interpreter.invoke()
    
    # Get output tensor
    output_data = interpreter.get_tensor(output_details[0]['index'])
    
    # Process predictions
    pred = output_data[0]
    harf_id = np.argmax(pred)
    confidence = float(pred[harf_id] * 100)  # Convert to float for JSON serialization
    
    # Get top 3 predictions - ensure proper conversion to Python native types
    top3_indices = np.argsort(pred)[-3:][::-1]
    top3_harfs = [(id_to_harf[int(idx)], float(pred[idx] * 100)) for idx in top3_indices]
    
    return {
        'predicted_harf': id_to_harf[int(harf_id)],
        'confidence': confidence,
        'top3': top3_harfs
    }

def get_assessment(confidence, expected_harf, predicted_harf):
    # Debugging
    print(f"Assessment - Expected: '{expected_harf}', Predicted: '{predicted_harf}', Confidence: {confidence:.2f}%")
    
    # Check if expected_harf is valid
    if expected_harf not in harf_to_id:
        print(f"WARNING: Invalid expected_harf: '{expected_harf}'")
        return "Error", f"Invalid reference letter: '{expected_harf}'", True
    
    # Check if the prediction matches the expected harf
    matched = predicted_harf == expected_harf
    
    # If not matched, return error assessment
    if not matched:
        return "Incorrect", f"You pronounced '{predicted_harf}' instead of '{expected_harf}'.", True
    
    # Determine assessment based on confidence for matched harfs
    if confidence >= 95:
        return "Perfect", "Your pronunciation is excellent! Keep it up.", False
    elif confidence >= 85:
        return "Excellent", "Your pronunciation is very good. With a bit more practice, it will be perfect.", False
    elif confidence >= 75:
        return "Good", "Your pronunciation is good, but there's room for improvement. Try to articulate more clearly.", False
    elif confidence >= 60:
        return "Needs Improvement", "You're on the right track, but your pronunciation needs more work. Focus on proper articulation points.", False
    else:
        return "Poor", "Your pronunciation needs significant improvement. Try listening to reference recordings and practice more.", False

@app.route('/analyze_harf', methods=['POST'])
def analyze_harf():
    try:
        # Check if audio file is present in request
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        expected_harf = request.form.get('expected_harf', '')
        
        # Debug logging
        print(f"Received request to analyze harf. Expected: '{expected_harf}'")
        
        # Check if filename is empty
        if audio_file.filename == '':
            return jsonify({'error': 'Empty filename'}), 400
        
        # Save the file temporarily
        temp_dir = tempfile.mkdtemp()
        temp_path = os.path.join(temp_dir, secure_filename(audio_file.filename))
        audio_file.save(temp_path)
        print(f"Audio saved temporarily at: {temp_path}")
        
        try:
            # Predict harf from the audio
            result = predict_harf(temp_path)
            
            # Get top prediction
            predicted_harf = result['predicted_harf']
            confidence = result['confidence']
            
            # If an expected harf was provided, add assessment
            if expected_harf:
                assessment, feedback, is_mismatch = get_assessment(confidence, expected_harf, predicted_harf)
                
                # Ensure all values are JSON serializable
                response_data = {
                    'predicted': predicted_harf,
                    'expected': expected_harf,
                    'confidence': float(confidence),  # Ensure this is a native Python float
                    'assessment': assessment,
                    'feedback': feedback,
                    'is_mismatch': bool(is_mismatch),  # Ensure this is a native Python bool
                    'top3': [(str(h), float(c)) for h, c in result['top3']]  # Convert to native Python types
                }
                return jsonify(response_data)
            else:
                # If no expected harf, just return prediction with JSON serializable types
                response_data = {
                    'predicted': predicted_harf,
                    'confidence': float(confidence),  # Ensure this is a native Python float
                    'top3': [(str(h), float(c)) for h, c in result['top3']]  # Convert to native Python types
                }
                return jsonify(response_data)
                
        except Exception as e:
            print(f"Error during audio processing or prediction: {str(e)}")
            traceback.print_exc()
            return jsonify({'error': f'Error analyzing audio: {str(e)}'}), 500
        finally:
            # Clean up temporary file
            if os.path.exists(temp_path):
                os.remove(temp_path)
            if os.path.exists(temp_dir):
                os.rmdir(temp_dir)
    
    except Exception as e:
        print(f"Unhandled exception in analyze_harf: {str(e)}")
        traceback.print_exc()
        return jsonify({'error': f'Server error: {str(e)}'}), 500


@app.route('/transcribe', methods=['POST'])
def transcribe():
    print("Received transcription request")
    
    if 'audio' not in request.files:
        print("Error: No audio file in request")
        return jsonify({'error': 'No audio file provided'}), 400
        
    audio_file = request.files['audio']
    print(f"Received audio file: {audio_file.filename}, content type: {audio_file.content_type}")
    
    temp_path = os.path.join(tempfile.gettempdir(), secure_filename(audio_file.filename))
    audio_file.save(temp_path)
    print(f"Saved audio to temporary path: {temp_path}")
    
    try:
        # Use Hugging Face Hub for inference - UPDATED TO MATCH THEIR EXAMPLE
        from huggingface_hub import InferenceClient
        
        print("Creating InferenceClient...")
        client = InferenceClient(
            provider="hf-inference",  # Add this
            api_key="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"  # Changed from token to api_key
        )
        
        print(f"Sending audio to Hugging Face API...")
        # Pass model here instead
        result = client.automatic_speech_recognition(
            temp_path, 
            model="tarteel-ai/whisper-base-ar-quran"
        )
        print(f"Received result from HF API: {result}")
        
        os.remove(temp_path)
        print("Temporary file removed")
        
        # Handle different response formats
        if isinstance(result, dict) and 'text' in result:
            text = result['text']
        elif isinstance(result, str):
            text = result
        else:
            text = str(result)
            
        print(f"Returning transcription: {text}")
        return jsonify({'text': text})
    except Exception as e:
        print(f"Error in transcription: {str(e)}")
        import traceback
        traceback.print_exc()
        
        # Check if file exists and remove
        if os.path.exists(temp_path):
            os.remove(temp_path)
            
        return jsonify({
            'error': str(e),
            'traceback': traceback.format_exc()
        }), 500
    
# Add to your existing Flask server in server/app.py

@app.route('/compare_recitation', methods=['POST'])
def compare_recitation():
    if 'user_audio' not in request.files or 'qari_audio' not in request.files:
        return jsonify({'error': 'Both user and qari audio files are required'}), 400
    
    try:
        # Get files
        user_audio = request.files['user_audio']
        qari_audio = request.files['qari_audio']
        qari_name = request.form.get('qari_name', 'Sheikh Abdul Basit')
        
        # Save temporarily
        temp_dir = tempfile.mkdtemp()
        user_path = os.path.join(temp_dir, secure_filename(user_audio.filename))
        qari_path = os.path.join(temp_dir, secure_filename(qari_audio.filename))
        
        user_audio.save(user_path)
        qari_audio.save(qari_path)
        
        # Import the LehjaModule
        from lehja_module import LehjaModule
        
        # Initialize the Lehja module
        lehja = LehjaModule(model_path="tarteel-ai/whisper-base-ar-quran")
        
        # Create a profile for the Qari
        profile = lehja.create_qari_profile(
            qari_name=qari_name,
            audio_paths=[qari_path],
            save_path=None  # No need to save permanently
        )
        
        # Compare the user's recitation
        comparison_results = lehja.compare_recitation(
            audio_path=user_path,
            qari_name=qari_name
        )
        
        # Clean up
        os.remove(user_path)
        os.remove(qari_path)
        os.rmdir(temp_dir)
        
        return jsonify(comparison_results)
        
    except Exception as e:
        print(f"Error in recitation comparison: {str(e)}")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
    

@app.route('/health', methods=['GET'])
def health_check():
    health_info = {
        'status': 'healthy',
        'model_loaded': interpreter is not None,
        'harfs_count': len(id_to_harf),
        'expected_count': 28,  # We expect 28 output classes
        'api_version': '1.1.0'
    }
    return jsonify(health_info)

# Add CORS support to allow requests from mobile app
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    return response

@app.route('/debug', methods=['GET'])
def debug_info():
    """Endpoint to check mappings and configurations"""
    debug_data = {
        'harfs': list(id_to_harf.values()),
        'model_input_shape': input_details[0]['shape'].tolist(),
        'model_output_shape': output_details[0]['shape'].tolist(),
        'mappings': {str(k): v for k, v in id_to_harf.items()},
        'reverse_mappings': {k: v for k, v in harf_to_id.items()}
    }
    return jsonify(debug_data)

# Add these imports to your app.py
import torch
from transformers import pipeline, AutoProcessor, AutoModelForSpeechSeq2Seq
import os
import tempfile
from werkzeug.utils import secure_filename
import time

# Global variable to store the loaded model (outside any route)
asr_pipeline = None

def load_local_model():
    """Load the model if it's not already loaded"""
    global asr_pipeline
    
    if asr_pipeline is None:
        print("Loading Tarteel Whisper model...")
        start_time = time.time()
        
        processor = AutoProcessor.from_pretrained("tarteel-ai/whisper-base-ar-quran")
        model = AutoModelForSpeechSeq2Seq.from_pretrained("tarteel-ai/whisper-base-ar-quran")
        
        # Create pipeline
        asr_pipeline = pipeline(
            "automatic-speech-recognition",
            model=model,
            tokenizer=processor.tokenizer,
            feature_extractor=processor.feature_extractor,
            max_new_tokens=128,
            chunk_length_s=30,
            batch_size=16,
            return_timestamps=False,
            device="cuda" if torch.cuda.is_available() else "cpu"
        )
        
        print(f"Model loaded in {time.time() - start_time:.2f} seconds")
    
    return asr_pipeline

# Add this route to your Flask app
@app.route('/transcribe_local', methods=['POST'])
def transcribe_local():
    print("Received transcription request for local model")
    
    if 'audio' not in request.files:
        print("Error: No audio file in request")
        return jsonify({'error': 'No audio file provided'}), 400
        
    audio_file = request.files['audio']
    print(f"Received audio file: {audio_file.filename}, content type: {audio_file.content_type}")
    
    temp_path = os.path.join(tempfile.gettempdir(), secure_filename(audio_file.filename))
    audio_file.save(temp_path)
    print(f"Saved audio to temporary path: {temp_path}")
    
    try:
        # Load the model if not already loaded
        pipe = load_local_model()
        
        # Process audio
        print("Transcribing audio...")
        start_time = time.time()
        result = pipe(temp_path)
        print(f"Transcription completed in {time.time() - start_time:.2f} seconds")
        
        # Clean up
        os.remove(temp_path)
        print("Temporary file removed")
        
        # Extract text from result
        if isinstance(result, dict) and 'text' in result:
            text = result['text']
        else:
            text = str(result)
            
        print(f"Transcription result: {text}")
        return jsonify({'text': text})
        
    except Exception as e:
        print(f"Error in transcription: {str(e)}")
        import traceback
        traceback.print_exc()
        
        # Cleanup
        if os.path.exists(temp_path):
            os.remove(temp_path)
            
        return jsonify({
            'error': str(e),
            'traceback': traceback.format_exc()
        }), 500


def load_audio_with_librosa(audio_path, sampling_rate=16000):
    """Load audio using librosa instead of ffmpeg"""
    waveform, sr = librosa.load(audio_path, sr=sampling_rate, mono=True)
    return {"array": waveform, "sampling_rate": sr}



if __name__ == '__main__':
    # Changed host to 0.0.0.0 to allow connections from any IP
    # Increased timeout for large audio files
    print("Pre-loading the model...")
    load_local_model()
    
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)