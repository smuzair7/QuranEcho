# Create a test.py file in your server directory
from huggingface_hub import InferenceClient

# Test the huggingface_hub library directly
client = InferenceClient(
    provider="hf-inference",
    api_key="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"
)

# Path to a sample audio file
sample_path = "C:\\Users\\THINK\\Desktop\\FYP\hudhaify_ayat1.wav"

# Call the API
result = client.automatic_speech_recognition(sample_path, model="tarteel-ai/whisper-base-ar-quran")

print(f"Result: {result}")