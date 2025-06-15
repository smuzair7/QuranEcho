@echo off
echo Installing required dependencies...
pip install -r requirements.txt

echo Starting Quran Echo ASR server...
echo Server will be available at http://localhost:5000
echo Use Ctrl+C to stop the server

python app.py
