import torch
from transformers import pipeline, AutoProcessor, AutoModelForSpeechSeq2Seq
import time

print("Starting model download and setup...")
start_time = time.time()

# Download and set up the model (this will cache it locally)
print("Loading model and processor...")

processor = AutoProcessor.from_pretrained("tarteel-ai/whisper-base-ar-quran")
model = AutoModelForSpeechSeq2Seq.from_pretrained("tarteel-ai/whisper-base-ar-quran")

# Create a pipeline for easy inference
pipe = pipeline(
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

# Test the model on a sample file
print("Testing model on a sample file...")
sample_path = "C:\\Users\\THINK\\Desktop\\FYP\\hudhaify_ayat1.wav"

result = pipe(sample_path)
print(f"Transcription result: {result}")

# Print out the model storage location for reference
import os
from transformers.utils import TRANSFORMERS_CACHE
print(f"Model is cached at: {TRANSFORMERS_CACHE}")

print("Setup complete! The model is now cached locally.")