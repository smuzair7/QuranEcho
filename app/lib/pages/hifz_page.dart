import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:math' show min;

class HifzPage extends StatefulWidget {
  const HifzPage({super.key});

  @override
  State<HifzPage> createState() => _HifzPageState();
}

class _HifzPageState extends State<HifzPage> {
  // Audio recording variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start recording';
  
  // API variables
  static const String _apiToken = "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";
  // Update to use the tarteel-ai/whisper-base-ar-quran model
  static const String _apiUrl = "https://api-inference.huggingface.co/models/tarteel-ai/whisper-base-ar-quran";
  bool _isProcessing = false;
  String? _apiResult;
  String? _transcription;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Start recording function
  Future<void> _startRecording() async {
    try {
      // Request permissions
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _recordingStatus = 'Permission denied for recording';
        });
        return;
      }

      // Get the temp directory
      final directory = await getTemporaryDirectory();
      String fileName = 'hifz_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = path.join(directory.path, fileName);

      // Configure recording for WAV format
      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 2, // Stereo recording
      );

      // Start recording
      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordingStatus = 'Recording in progress...';
        _recordingPath = filePath;
      });
    } catch (e) {
      setState(() {
        _recordingStatus = 'Recording error: ${e.toString()}';
      });
    }
  }

  // Stop recording function
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Recording saved';
          _recordingPath = path;
        });
      } else {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Failed to save recording';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Error when stopping: ${e.toString()}';
      });
    }
  }

  // Play recording function
  Future<void> _playRecording() async {
    if (_recordingPath != null) {
      try {
        await _audioPlayer.setFilePath(_recordingPath!);
        _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _recordingStatus = 'Playing recording...';
        });

        // Listen for playback completion
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _recordingStatus = 'Ready to record';
            });
          }
        });
      } catch (e) {
        setState(() {
          _recordingStatus = 'Error playing: ${e.toString()}';
        });
      }
    } else {
      setState(() {
        _recordingStatus = 'No recording to play';
      });
    }
  }

  // Stop playback function
  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _recordingStatus = 'Ready to record';
    });
  }
  
  // Send audio to Hugging Face API
  Future<void> _processAudioWithAPI() async {
    if (_recordingPath == null) {
      setState(() {
        _apiResult = "No recording available to process";
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _apiResult = "Processing audio...";
      _transcription = null;
    });
    
    // Read file as bytes - do this outside the retry loop to read the file only once
    final File audioFile = File(_recordingPath!);
    final List<int> audioBytes;
    
    try {
      audioBytes = await audioFile.readAsBytes();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _apiResult = "Error reading audio file: ${e.toString()}";
      });
      return;
    }
    
    // Prepare API request
    final headers = {
      "Authorization": "Bearer $_apiToken",
      "Content-Type": "audio/wav",  // Specify correct content type for audio
    };
    
    // Retry configuration
    const int maxRetries = 4;
    const int initialDelayMs = 1000; // Start with 1 second delay
    int currentRetry = 0;
    bool success = false;
    
    while (currentRetry < maxRetries && !success) {
      try {
        if (currentRetry > 0) {
          // Update status on retry
          setState(() {
            _apiResult = "Retry attempt ${currentRetry}/${maxRetries-1}...";
          });
          
          // Exponential backoff - wait longer between each retry
          final delayMs = initialDelayMs * (1 << (currentRetry - 1)); // 1s, 2s, 4s, 8s
          await Future.delayed(Duration(milliseconds: delayMs));
        }
        
        debugPrint("API call attempt ${currentRetry + 1}/${maxRetries}: Sending ${audioBytes.length} bytes to Tarteel AI Whisper Quran model");
        
        // Make API request
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: headers,
          body: audioBytes,
        );
        
        debugPrint("API Response Status: ${response.statusCode}");
        debugPrint("API Response Body: ${response.body.substring(0, min(100, response.body.length))}...");
        
        if (response.statusCode == 200) {
          // Process successful response
          final decodedResponse = jsonDecode(response.body);
          
          // Extract transcription from the response
          String text = '';
          if (decodedResponse is Map && decodedResponse.containsKey('text')) {
            text = decodedResponse['text'];
          } else if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
            text = decodedResponse[0]['generated_text'] ?? '';
          } else {
            text = decodedResponse.toString();
          }
          
          // Fix Arabic text encoding if needed
          text = _fixArabicEncoding(text);
          
          setState(() {
            _isProcessing = false;
            _transcription = text;
            _apiResult = "Successfully processed audio with Tarteel AI Quran model";
          });
          
          success = true; // Mark as successful to exit the retry loop
          break;
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          // 503 Service Unavailable - The model is likely still loading (cold start)
          // 429 Too Many Requests - Rate limiting
          debugPrint("${response.statusCode} received - Model is likely still loading, will retry");
          
          // Will retry - don't mark as success
          currentRetry++;
        } else {
          // Other error types that won't benefit from retry
          setState(() {
            _isProcessing = false;
            _apiResult = "API Error ${response.statusCode}\n${response.reasonPhrase}\n\nPlease check your API token or try another model.";
          });
          
          if (response.statusCode == 400) {
            debugPrint("400 Bad Request - This might indicate an issue with the audio format or model compatibility");
          } else if (response.statusCode == 401) {
            debugPrint("401 Unauthorized - Check if your API token is valid");
          }
          
          break; // Exit retry loop for errors that won't be fixed by retrying
        }
      } catch (e) {
        // Network or other errors might benefit from retry
        debugPrint("Exception during API call: ${e.toString()}, will retry");
        currentRetry++;
        
        // If we've exhausted all retries, show error message
        if (currentRetry >= maxRetries) {
          setState(() {
            _isProcessing = false;
            _apiResult = "Error processing audio after $maxRetries attempts: ${e.toString()}";
          });
        }
      }
    }
    
    // If we've used all retries and still didn't succeed
    if (!success && currentRetry >= maxRetries) {
      setState(() {
        _isProcessing = false;
        _apiResult = "API failed to respond after $maxRetries attempts. The model may still be loading. Please try again in a minute.";
      });
    }
  }
  
  // Helper method to fix Arabic encoding issues with comprehensive replacements
  String _fixArabicEncoding(String text) {
    // If the text contains encoding issues
    if (text.contains('Ù') || text.contains('Ø') || text.contains('Ú')) {
      try {
        // Try to decode as UTF-8 first
        final decoded = utf8.decode(text.codeUnits);
        return decoded;
      } catch (e) {
        // If UTF-8 decoding fails, apply comprehensive replacements
        return text
            // Arabic letters
            .replaceAll('Ø§', 'ا') // Alif
            .replaceAll('Ø£', 'أ') // Alif with hamza above
            .replaceAll('Ø¢', 'آ') // Alif madda
            .replaceAll('Ø¥', 'إ') // Alif with hamza below
            .replaceAll('Ø¨', 'ب') // Ba
            .replaceAll('Øª', 'ت') // Ta
            .replaceAll('Ø«', 'ث') // Tha
            .replaceAll('Ø¬', 'ج') // Jim
            .replaceAll('Ø­', 'ح') // Ha
            .replaceAll('Ø®', 'خ') // Kha
            .replaceAll('Ø¯', 'د') // Dal
            .replaceAll('Ø°', 'ذ') // Thal
            .replaceAll('Ø±', 'ر') // Ra
            .replaceAll('Ø²', 'ز') // Zay
            .replaceAll('Ø³', 'س') // Sin
            .replaceAll('Ø´', 'ش') // Shin
            .replaceAll('Ø¹', 'ع') // Ain
            .replaceAll('Ø´', 'ش') // Shin
            .replaceAll('Øµ', 'ص') // Sad
            .replaceAll('Ø¶', 'ض') // Dad
            .replaceAll('Ø·', 'ط') // Ta (emphatic)
            .replaceAll('Ø¸', 'ظ') // Zah
            .replaceAll('Ø¹', 'ع') // Ain
            .replaceAll('Øº', 'غ') // Ghayn
            .replaceAll('Ù', 'ف') // Fa
            .replaceAll('Ù', 'ق') // Qaf
            .replaceAll('Ù', 'ك') // Kaf
            .replaceAll('Ù', 'ل') // Lam
            .replaceAll('Ù', 'م') // Mim
            .replaceAll('Ù', 'ن') // Nun
            .replaceAll('Ù', 'ه') // Ha
            .replaceAll('Ù', 'و') // Waw
            .replaceAll('Ù', 'ي') // Ya
            
            // Diacritics
            .replaceAll('Ù', 'َ') // Fatha
            .replaceAll('Ù', 'ُ') // Damma
            .replaceAll('Ù', 'ِ') // Kasra
            .replaceAll('Ù', 'ً') // Tanwin Fath (double fatha)
            .replaceAll('Ù', 'ٌ') // Tanwin Damm (double damma)
            .replaceAll('Ù', 'ٍ') // Tanwin Kasr (double kasra)
            .replaceAll('Ù', 'ّ') // Shadda
            .replaceAll('Ù', 'ْ') // Sukun
            
            // Additional Arabic-specific characters
            .replaceAll('Ø©', 'ة') // Ta marbuta
            .replaceAll('Ø¡', 'ء') // Hamza
            .replaceAll('Ù', 'ئ') // Ya with hamza
            .replaceAll('Ù', 'ؤ') // Waw with hamza
            
            // Punctuation and numerals
            .replaceAll('Ø', '٠') // Arabic zero
            .replaceAll('Ù', '١') // Arabic one
            .replaceAll('Ù', '٢') // Arabic two
            .replaceAll('Ù', '٣') // Arabic three
            .replaceAll('Ù', '٤') // Arabic four
            .replaceAll('Ù', '٥') // Arabic five
            .replaceAll('Ù', '٦') // Arabic six
            .replaceAll('Ù', '٧') // Arabic seven
            .replaceAll('Ù', '٨') // Arabic eight
            .replaceAll('Ù', '٩') // Arabic nine
            
            // Special cases
            .replaceAll('Ù Ù', 'لا') // Lam-alif ligature
            .replaceAll('Ù Ø£', 'لأ') // Lam-alif with hamza above
            .replaceAll('Ù Ø¥', 'لإ') // Lam-alif with hamza below
            
            // Common Quranic symbols
            .replaceAll('Û', '۞') // Sajdah
            .replaceAll('Û', '۝') // Ruku/Section
            
            // Fix spaces and double encoding issues
            .replaceAll('%20', ' ') // Space
            .replaceAll('  ', ' '); // Double space to single space
      }
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hifz'),
        backgroundColor: const Color(0xFF00A896),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Hifz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Memorize the Quran with spaced repetition techniques',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),
              
              // Recording status text
              Text(
                _recordingStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Recording controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  ElevatedButton(
                    onPressed: _isPlaying ? null : (_isRecording ? _stopRecording : _startRecording),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 36,
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Play button (only enabled if recording exists)
                  ElevatedButton(
                    onPressed: (_recordingPath != null && !_isRecording) 
                        ? (_isPlaying ? _stopPlayback : _playRecording)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.orange : const Color(0xFF1F8A70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 36,
                    ),
                  ),
                ],
              ),
              
              if (_recordingPath != null) ...[
                const SizedBox(height: 30),
                Text(
                  'Recording saved at:\n${_recordingPath!.split('/').last}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                
                // API Processing Button
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: (_isProcessing || _recordingPath == null) ? null : _processAudioWithAPI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(Icons.api),
                  label: Text(_isProcessing ? 'Processing...' : 'Analyze with Hugging Face API'),
                ),
                
                // Transcription Display
                if (_transcription != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1F8A70), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transcription:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1F8A70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _transcription!,
                          style: const TextStyle(
                            fontSize: 18, // Slightly larger for better readability
                            fontWeight: FontWeight.w500,
                            color: Colors.black, // Set text color to black
                            fontFamily: 'Scheherazade', // Use Arabic font if available
                          ),
                          textDirection: TextDirection.rtl, // Right to left for Arabic
                        ),
                      ],
                    ),
                  ),
                ],
                
                // API Result/Error Display
                if (_apiResult != null && _apiResult!.contains('Error')) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _apiResult!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}