import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:math' show min;
import 'dart:async';
import 'package:queue/queue.dart';

class HifzPage extends StatefulWidget {
  const HifzPage({super.key});

  @override
  State<HifzPage> createState() => _HifzPageState();
}

class _HifzPageState extends State<HifzPage> {
  // Add surah info variables
  int? surahNumber;
  String? surahName;
  String? arabicName;
  int? ayahCount;

  // Audio recording variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start recording';
  
  // API variables
  static const String _apiToken = "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";
  static const String _apiUrl = "https://api-inference.huggingface.co/models/tarteel-ai/whisper-base-ar-quran";
  bool _isProcessing = false;
  String? _apiResult;
  List<String> _transcriptions = [];

  // Queue for API requests
  final Queue _apiQueue = Queue();

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the arguments passed from the select surah page
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      setState(() {
        surahNumber = args['surahNumber'];
        surahName = args['surahName'];
        arabicName = args['arabicName'];
        ayahCount = args['ayahCount'];
      });
    }
  }

  // Start recording function
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _recordingStatus = 'Permission denied for recording';
        });
        return;
      }

      final directory = await getTemporaryDirectory();
      String fileName = 'hifz_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = path.join(directory.path, fileName);

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 2,
      );

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
        _enqueueApiRequest(path);
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

  // Enqueue API request
  void _enqueueApiRequest(String path) {
    _apiQueue.add(() => _processAudioWithAPI(path));
  }

  // Process audio with API
  Future<void> _processAudioWithAPI(String path) async {
    setState(() {
      _isProcessing = true;
      _apiResult = "Processing audio...";
    });

    final File audioFile = File(path);
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

    final headers = {
      "Authorization": "Bearer $_apiToken",
      "Content-Type": "audio/wav",
    };

    const int maxRetries = 4;
    const int initialDelayMs = 1000;
    int currentRetry = 0;
    bool success = false;

    while (currentRetry < maxRetries && !success) {
      try {
        if (currentRetry > 0) {
          setState(() {
            _apiResult = "Retry attempt ${currentRetry}/${maxRetries-1}...";
          });
          final delayMs = initialDelayMs * (1 << (currentRetry - 1));
          await Future.delayed(Duration(milliseconds: delayMs));
        }

        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: headers,
          body: audioBytes,
        );

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          String text = '';
          if (decodedResponse is Map && decodedResponse.containsKey('text')) {
            text = decodedResponse['text'];
          } else if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
            text = decodedResponse[0]['generated_text'] ?? '';
          } else {
            text = decodedResponse.toString();
          }

          text = _fixArabicEncoding(text);

          setState(() {
            _isProcessing = false;
            _transcriptions.add(text);
            _apiResult = "Successfully processed audio with Tarteel AI Quran model";
          });

          success = true;
          break;
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          currentRetry++;
        } else {
          setState(() {
            _isProcessing = false;
            _apiResult = "API Error ${response.statusCode}\n${response.reasonPhrase}\n\nPlease check your API token or try another model.";
          });
          break;
        }
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          setState(() {
            _isProcessing = false;
            _apiResult = "Error processing audio after $maxRetries attempts: ${e.toString()}";
          });
        }
      }
    }

    if (!success && currentRetry >= maxRetries) {
      setState(() {
        _isProcessing = false;
        _apiResult = "API failed to respond after $maxRetries attempts. The model may still be loading. Please try again in a minute.";
      });
    }
  }

  // Helper method to fix Arabic encoding issues
  String _fixArabicEncoding(String text) {
    if (text.contains('Ù') || text.contains('Ø') || text.contains('Ú')) {
      try {
        final decoded = utf8.decode(text.codeUnits);
        return decoded;
      } catch (e) {
        return text
            .replaceAll('Ø§', 'ا')
            .replaceAll('Ø£', 'أ')
            .replaceAll('Ø¢', 'آ')
            .replaceAll('Ø¥', 'إ')
            .replaceAll('Ø¨', 'ب')
            .replaceAll('Øª', 'ت')
            .replaceAll('Ø«', 'ث')
            .replaceAll('Ø¬', 'ج')
            .replaceAll('Ø­', 'ح')
            .replaceAll('Ø®', 'خ')
            .replaceAll('Ø¯', 'د')
            .replaceAll('Ø°', 'ذ')
            .replaceAll('Ø±', 'ر')
            .replaceAll('Ø²', 'ز')
            .replaceAll('Ø³', 'س')
            .replaceAll('Ø´', 'ش')
            .replaceAll('Ø¹', 'ع')
            .replaceAll('Øµ', 'ص')
            .replaceAll('Ø¶', 'ض')
            .replaceAll('Ø·', 'ط')
            .replaceAll('Ø¸', 'ظ')
            .replaceAll('Ø¹', 'ع')
            .replaceAll('Øº', 'غ')
            .replaceAll('Ù', 'ف')
            .replaceAll('Ù', 'ق')
            .replaceAll('Ù', 'ك')
            .replaceAll('Ù', 'ل')
            .replaceAll('Ù', 'م')
            .replaceAll('Ù', 'ن')
            .replaceAll('Ù', 'ه')
            .replaceAll('Ù', 'و')
            .replaceAll('Ù', 'ي')
            .replaceAll('Ù', 'َ')
            .replaceAll('Ù', 'ُ')
            .replaceAll('Ù', 'ِ')
            .replaceAll('Ù', 'ً')
            .replaceAll('Ù', 'ٌ')
            .replaceAll('Ù', 'ٍ')
            .replaceAll('Ù', 'ّ')
            .replaceAll('Ù', 'ْ')
            .replaceAll('Ø©', 'ة')
            .replaceAll('Ø¡', 'ء')
            .replaceAll('Ù', 'ئ')
            .replaceAll('Ù', 'ؤ')
            .replaceAll('Ø', '٠')
            .replaceAll('Ù', '١')
            .replaceAll('Ù', '٢')
            .replaceAll('Ù', '٣')
            .replaceAll('Ù', '٤')
            .replaceAll('Ù', '٥')
            .replaceAll('Ù', '٦')
            .replaceAll('Ù', '٧')
            .replaceAll('Ù', '٨')
            .replaceAll('Ù', '٩')
            .replaceAll('Ù Ù', 'لا')
            .replaceAll('Ù Ø£', 'لأ')
            .replaceAll('Ù Ø¥', 'لإ')
            .replaceAll('Û', '۞')
            .replaceAll('Û', '۝')
            .replaceAll('%20', ' ')
            .replaceAll('  ', ' ');
      }
    }
    return text;
  }

  // Stop playback function
  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  // Play recording function
  Future<void> _playRecording() async {
    if (_recordingPath != null) {
      await _audioPlayer.setFilePath(_recordingPath!);
      _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surahName != null ? 'Hifz: $surahName' : 'Hifz'),
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
              // Display surah info if available
              if (surahNumber != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A896).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00A896), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        arabicName ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Scheherazade',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Text(
                        'Surah ${surahNumber ?? ''}: ${surahName ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${ayahCount ?? ''} Ayahs',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
              
              // Rest of the original build method content
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
                  onPressed: (_isProcessing || _recordingPath == null) ? null : () => _enqueueApiRequest(_recordingPath!),
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
                if (_transcriptions.isNotEmpty) ...[
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
                          'Transcriptions:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1F8A70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var transcription in _transcriptions)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              transcription,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontFamily: 'Scheherazade',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }
}