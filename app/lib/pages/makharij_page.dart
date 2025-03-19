import 'dart:io';
import 'dart:async'; // Add this import for TimeoutException
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MakharijPage extends StatefulWidget {
  final String? letter;

  const MakharijPage({super.key, this.letter});

  @override
  State<MakharijPage> createState() => _MakharijPageState();
}

class _MakharijPageState extends State<MakharijPage> {
  // Audio recording variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start recording';

  // Server communication variables
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;

  // Arabic to English letter mapping - updated to match the model's training classes
  final Map<String, String> _arabicToEnglishMap = {
    'ع': 'Aain', // 0
    'ا': 'Alif', // 1
    'ب': 'Ba', // 2
    'د': 'Dal', // 3
    'ض': 'Duad', // 4
    'ف': 'Faa', // 5
    'غ': 'Ghain', // 6
    'ه': 'Haa', // 7
    'ح': 'Hha', // 8
    'ج': 'Jeem', // 9
    'ك': 'Kaif', // 10
    'خ': 'Kha', // 11
    'ل': 'Laam', // 12
    'م': 'Meem', // 13
    'ن': 'Noon', // 14
    'ق': 'Qauf', // 15
    'ر': 'Raa', // 16
    'ث': 'Sa', // 17 - This is Sa (ث - Thaa with 3 dots)
    'ص': 'Saud', // 18
    'س': 'Seen', // 19 - This is Seen (س)
    'ش': 'Sheen', // 20
    'ت': 'Ta', // 21
    'ط': 'Tua', // 22
    'و': 'Wao', // 23
    'ي': 'Yaa', // 24
    'ز': 'Zaa', // 25
    'ذ': 'Zhal', // 26
    'ظ': 'Zua' // 27
  };

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
      String fileName =
          'recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      // If a letter is provided, include it in the filename
      if (widget.letter != null) {
        fileName = '${widget.letter}_$fileName';
      }

      final filePath = path.join(directory.path, fileName);

      // Configure recording for WAV format
      const config = RecordConfig(
        encoder: AudioEncoder.wav, // Changed to WAV encoder
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

  // Send recording to server for analysis
  Future<void> _analyzeRecording() async {
    if (_recordingPath == null) {
      setState(() {
        _recordingStatus = 'No recording to analyze';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _recordingStatus = 'Analyzing pronunciation...';
      _analysisResult = null;
    });

    try {
      // Updated with your actual laptop IP address
      // Option 1: For physical device on same network as laptop
      final url = Uri.parse('http://192.168.18.37:5000/analyze_harf');

      // Option 2: For Android Emulator (uncomment if using emulator)
      // final url = Uri.parse('http://10.0.2.2:5000/analyze_harf');

      final request = http.MultipartRequest('POST', url);

      // Add more detailed logging
      print('Sending audio file: $_recordingPath');
      print('Sending to server: ${url.toString()}');

      // Get the expected harf in English format
      final expectedHarf = widget.letter != null
          ? _arabicToEnglishMap[widget.letter!] ?? ''
          : '';

      print('Expected harf: $expectedHarf');

      // Add the audio file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        _recordingPath!,
      ));
      request.fields['expected_harf'] = expectedHarf;

      // Send the request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _isProcessing = false;
          _analysisResult = result;
          _recordingStatus = 'Analysis complete';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _recordingStatus = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error details: $e');
      setState(() {
        _isProcessing = false;
        _recordingStatus = 'Connection error: ${e.toString()}';
      });

      // Show a more user-friendly error dialog
      _showConnectionErrorDialog();
    }
  }

  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_connected_no_internet_4_outlined,
              color: Colors.red,
              size: 50,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not connect to the server. Please check:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '• Make sure the Flask server is running\n'
              '• Check your network connection\n'
              '• Verify the server address in the app',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Get color based on assessment category
  Color _getAssessmentColor(String assessment) {
    switch (assessment) {
      case 'Perfect':
        return Colors.green;
      case 'Excellent':
        return Colors.lightGreen;
      case 'Good':
        return Colors.amber;
      case 'Needs Improvement':
        return Colors.orange;
      case 'Poor':
        return Colors.redAccent;
      case 'Incorrect':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAnalysisResultCard() {
    if (_analysisResult == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Pronunciation Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Display error message if there's an error key
          if (_analysisResult!.containsKey('error')) ...[
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _analysisResult!['error'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]
          // Handle mismatch case specially
          else if (_analysisResult!.containsKey('is_mismatch') &&
              _analysisResult!['is_mismatch'] == true) ...[
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Incorrect Letter',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Expected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F8A70).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.letter ?? '',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Scheherazade',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 40),
                      Column(
                        children: [
                          Text(
                            'Detected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                // Find Arabic letter that corresponds to the predicted harf
                                _arabicToEnglishMap.entries
                                    .firstWhere(
                                      (entry) =>
                                          entry.value ==
                                          _analysisResult!['predicted'],
                                      orElse: () => const MapEntry('?', '?'),
                                    )
                                    .key,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Scheherazade',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _analysisResult!['feedback'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _analysisResult = null;
                      _recordingStatus = 'Ready to record again';
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F8A70),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ]
          // Display successful pronunciation assessment
          else ...[
            // Success icon and assessment text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: _getAssessmentColor(_analysisResult!['assessment']),
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  _analysisResult!['assessment'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getAssessmentColor(_analysisResult!['assessment']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display confidence with a progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence: ${_analysisResult!['confidence'].toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _analysisResult!['confidence'] / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAssessmentColor(_analysisResult!['assessment']),
                    ),
                  ),
                ),
              ],
            ),

            // Display feedback
            if (_analysisResult!.containsKey('feedback')) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAssessmentColor(_analysisResult!['assessment'])
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color:
                          _getAssessmentColor(_analysisResult!['assessment']),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _analysisResult!['feedback'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Try again button
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _analysisResult = null;
                _recordingStatus = 'Ready to record again';
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Practice Again'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: _getAssessmentColor(_analysisResult!['assessment'])),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.letter != null
            ? 'Recording: ${widget.letter}'
            : 'Pronunciation Recording'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display selected letter if available
              if (widget.letter != null)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F8A70).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.letter!,
                      style: const TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Scheherazade',
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.record_voice_over,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),

              const SizedBox(height: 20),

              Text(
                widget.letter != null ? 'Practice Pronouncing' : 'Makharij',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.letter != null
                    ? 'Record yourself pronouncing this letter correctly'
                    : 'Learn proper pronunciation points of Arabic letters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 40),

              // Recording status text
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isRecording ? Icons.mic : Icons.info_outline,
                      color: _isRecording ? Colors.red : Colors.grey[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _recordingStatus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isRecording ? Colors.red : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recording controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  ElevatedButton(
                    onPressed: _isPlaying || _isProcessing
                        ? null
                        : (_isRecording ? _stopRecording : _startRecording),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isRecording ? Colors.red : const Color(0xFF1F8A70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                      elevation: 4,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 36,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Play button (only enabled if recording exists)
                  ElevatedButton(
                    onPressed: (_recordingPath != null &&
                            !_isRecording &&
                            !_isProcessing)
                        ? (_isPlaying ? _stopPlayback : _playRecording)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isPlaying ? Colors.orange : const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                      elevation: 4,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 36,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Analyze button
                  ElevatedButton(
                    onPressed: (_recordingPath != null &&
                            !_isRecording &&
                            !_isPlaying &&
                            !_isProcessing)
                        ? _analyzeRecording
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                      elevation: 4,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.analytics_outlined,
                            size: 36,
                          ),
                  ),
                ],
              ),

              // Analysis results
              if (_analysisResult != null) ...[
                const SizedBox(height: 40),
                _buildAnalysisResultCard(),
              ],

              if (_recordingPath != null &&
                  _analysisResult == null &&
                  !_isProcessing) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Recording ready. Press analyze to check pronunciation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
