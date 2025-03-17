import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:queue/queue.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class RevisionPage extends StatefulWidget {
  final List<Map<String, dynamic>> ayahs;
  final List<int> memorizedIndices;
  final int defaultStartIndex;
  final int defaultEndIndex;
  final String surahName;

  const RevisionPage({
    required this.ayahs,
    required this.memorizedIndices,
    required this.defaultStartIndex,
    required this.defaultEndIndex,
    required this.surahName,
    Key? key,
  }) : super(key: key);

  @override
  State<RevisionPage> createState() => _RevisionPageState();
}

class _RevisionPageState extends State<RevisionPage> {
  // Add these new variables
  bool _isFlowRecordingMode = false;
  int _currentRecitingIndex = 0;
  Map<int, String> _pendingTranscriptions = {};
  Map<int, int> _matchScores = {};
  Set<int> _correctlyRecitedIndices = {};
  bool _errorMessageVisible = false;
  String _errorFeedback = "";

  // Current revision range
  late int _startIndex;
  late int _endIndex;
  late int _currentIndex;

  // Audio recording variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Select a range to revise';

  // Recording visibility
  bool _isTextVisible = true;

  // API variables
  static const String _apiToken = "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";
  static const String _apiUrl = "https://api-inference.huggingface.co/models/tarteel-ai/whisper-base-ar-quran";
  bool _isProcessing = false;
  String? _apiResult;
  List<String> _transcriptions = [];
  
  // Queue for API requests
  final Queue _apiQueue = Queue();

  @override
  void initState() {
    super.initState();
    _startIndex = widget.defaultStartIndex;
    _endIndex = widget.defaultEndIndex; 
    _currentIndex = _startIndex;
    
    // Configure the API Queue
    
    _showSetupDialog();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showSetupDialog() {
    int startIndex = _startIndex;
    int endIndex = _endIndex;
    
    // Show dialog after the build is complete
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false, // User must pick a range
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF212121),
              title: const Text(
                'Revision Range',
                style: TextStyle(color: Colors.white)
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Revision range slider
                  Text(
                    'Select Ayah Range to Revise:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(startIndex.toDouble(), endIndex.toDouble()),
                    min: 0,
                    max: widget.memorizedIndices.isEmpty ? 0 : widget.ayahs.length - 1.toDouble(),
                    divisions: widget.ayahs.isEmpty ? 1 : widget.ayahs.length - 1,
                    labels: RangeLabels(
                      'Ayah ${widget.ayahs[startIndex]['ayahNumber']}',
                      'Ayah ${widget.ayahs[endIndex]['ayahNumber']}',
                    ),
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.grey.shade700,
                    onChanged: (RangeValues values) {
                      setState(() {
                        startIndex = values.start.round();
                        endIndex = values.end.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'From Ayah ${widget.ayahs[startIndex]['ayahNumber']} to Ayah ${widget.ayahs[endIndex]['ayahNumber']}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Return to previous page
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Update the state with selected range
                    this.setState(() {
                      _startIndex = startIndex;
                      _endIndex = endIndex;
                      _currentIndex = startIndex;
                      _recordingStatus = 'Tap to start revising';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('Start Revision'),
                ),
              ],
            );
          },
        ),
      );
    });
  }
  
  Future<void> _startRecording(Map<String, dynamic> ayah) async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _recordingStatus = 'Permission denied for recording';
        });
        return;
      }

      // Hide the text when recording starts
      setState(() {
        _isTextVisible = false;
      });

      final directory = await getTemporaryDirectory();
      String fileName = 'revision_surah_${ayah['surahNumber']}_ayah_${ayah['ayahNumber']}_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = path.join(directory.path, fileName);

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 2,
      );

      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordingStatus = 'Reciting Ayah ${ayah['ayahNumber']}...';
        _recordingPath = filePath;
      });
    } catch (e) {
      setState(() {
        _recordingStatus = 'Recording error: ${e.toString()}';
        _isTextVisible = true; // Show text again if recording fails
      });
    }
  }

  Future<void> _stopRecording(Map<String, dynamic> ayah) async {
    try {
      final path = await _audioRecorder.stop();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Recitation saved';
          _recordingPath = path;
        });

        // Enqueue API request for transcription
        _enqueueApiRequest(path);
      } else {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Failed to save recitation';
          _isTextVisible = true; // Show text again if recording fails
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Error when stopping: ${e.toString()}';
        _isTextVisible = true; // Show text again if recording fails
      });
    }
  }

  void _enqueueApiRequest(String path) {
    _apiQueue.add(() async {
      await _processAudioWithAPI(path);
      // Set processing to false when each task completes
      setState(() {
        _isProcessing = false;
      });
    });
  }

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
            _apiResult = "Retry attempt ${currentRetry}/${maxRetries - 1}...";
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

    if (success) {
      // Check transcription against original text
      _verifyRecitation();
    }
  }

  String _fixArabicEncoding(String text) {
    if (text.contains('Ù') || text.contains('Ø') || text.contains('Ú')) {
      try {
        // Try using utf8.decode with latin1.encode
        return utf8.decode(latin1.encode(text));
      } catch (e) {
        try {
          // Try another common approach
          final bytes = text.codeUnits.map((c) => c < 128 ? c : (c - 848)).toList();
          return String.fromCharCodes(bytes);
        } catch (e2) {
          // Fall back to manual replacement
          final Map<String, String> replacements = {
            'Ø§': 'ا', 'Ø£': 'أ', 'Ø¢': 'آ', 'Ø¥': 'إ', 'Ø¨': 'ب',
            'Øª': 'ت', 'Ø«': 'ث', 'Ø¬': 'ج', 'Ø­': 'ح', 'Ø®': 'خ',
            'Ø¯': 'د', 'Ø°': 'ذ', 'Ø±': 'ر', 'Ø²': 'ز', 'Ø³': 'س',
            'Ø´': 'ش', 'Øµ': 'ص', 'Ø¶': 'ض', 'Ø·': 'ط', 'Ø¸': 'ظ',
            'Ø¹': 'ع', 'Øº': 'غ', 'Ù': 'ف', 'Ù‚': 'ق', 'Ùƒ': 'ك',
            'Ù„': 'ل', 'Ù…': 'م', 'Ù†': 'ن', 'Ù‡': 'ه', 'Ùˆ': 'و',
            'ÙŠ': 'ي', 'Ø©': 'ة', 'Ø¡': 'ء', 'Ù‰': 'ى', 'ÙŽ': 'َ',
            'Ù': 'ُ', 'Ù': 'ِ', 'Ù‹': 'ً', 'ÙŒ': 'ٌ', 'Ù': 'ٍ',
            'Ù': 'ّ', 'Ù': 'ْ',
          };

          String result = text;
          replacements.forEach((key, value) {
            result = result.replaceAll(key, value);
          });
          return result;
        }
      }
    }
    return text;
  }

  void _verifyRecitation() {
    if (_transcriptions.isEmpty) return;

    Map<String, dynamic> currentAyah = widget.ayahs[_currentIndex];
    String originalText = currentAyah['displayText'] ?? currentAyah['text'];
    String cleanOriginal = _prepareTextForComparison(originalText);
    String cleanTranscription = _prepareTextForComparison(_transcriptions.last);

    // Calculate match percentage
    int matchScore = _calculateMatchScore(cleanTranscription, cleanOriginal);
    int passThreshold = 70; // 70% accuracy required to pass

    bool isPassed = matchScore >= passThreshold;

    setState(() {
      // Always show text after recitation for review
      _isTextVisible = true;
      
      // Show success message based on result
      _recordingStatus = isPassed 
          ? 'MashaAllah! ($matchScore% match)'
          : 'Try again ($matchScore% match)';
    });
  }

  // Helper methods for text comparison
  String _prepareTextForComparison(String text) {
    // Remove diacritics and normalize text
    final nonEssentialDiacritics = [
      '\u064B', '\u064C', '\u064D', '\u064E', '\u064F',
      '\u0650', '\u0651', '\u0652', '\u0653', '\u0654',
      '\u0655', '\u0656', '\u0657', '\u0658', '\u0659',
      '\u065A', '\u065B', '\u065C', '\u065D', '\u065E',
      '\u065F', '\u0670'
    ];

    String result = text;
    for (String diacritic in nonEssentialDiacritics) {
      result = result.replaceAll(diacritic, '');
    }

    // Normalize alef forms
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');

    return result.trim();
  }

  int _calculateMatchScore(String transcription, String original) {
    List<String> originalWords = original.split(' ');
    List<String> transcriptionWords = transcription.split(' ');

    Set<String> originalWordsSet = originalWords.toSet();
    int correctWords = 0;

    for (String word in transcriptionWords) {
      if (originalWordsSet.contains(word)) {
        correctWords++;
      }
    }

    int totalWords = math.max(originalWords.length, transcriptionWords.length);
    if (totalWords == 0) return 0;

    return (correctWords * 100 ~/ totalWords);
  }

  Widget _buildTranscriptionWithHighlightedErrors(
    String transcription, 
    Map<String, dynamic> ayah,
    {double textSize = 18}
  ) {
    String originalText = ayah['displayText'] ?? ayah['text'];
    
    // Clean up text for better comparison
    String cleanOriginal = _prepareTextForComparison(originalText);
    String cleanTranscription = _prepareTextForComparison(transcription);
    
    List<String> originalWords = cleanOriginal.split(' ');
    List<String> transcriptionWords = cleanTranscription.split(' ');
    
    // Create a set of original words for quick matching
    Set<String> originalWordsSet = originalWords.toSet();
    
    // Create list of TextSpans for rich text display
    List<TextSpan> textSpans = [];
    
    for (int i = 0; i < transcriptionWords.length; i++) {
      String currentWord = transcriptionWords[i];
      bool isCorrect = originalWordsSet.contains(currentWord);
      
      textSpans.add(
        TextSpan(
          text: i < transcriptionWords.length - 1 ? '$currentWord ' : currentWord,
          style: TextStyle(
            fontSize: textSize,
            fontFamily: 'Scheherazade',
            fontWeight: FontWeight.w500,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
      );
    }
    
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(children: textSpans),
    );
  }

  void _moveToNext() {
    if (_currentIndex < _endIndex) {
      setState(() {
        _currentIndex++;
        _transcriptions = [];
        _isTextVisible = true;
        _recordingStatus = 'Tap to start revising';
      });
    }
  }

  void _moveToPrevious() {
    if (_currentIndex > _startIndex) {
      setState(() {
        _currentIndex--;
        _transcriptions = [];
        _isTextVisible = true;
        _recordingStatus = 'Tap to start revising';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAyahs = _endIndex - _startIndex + 1;
    final currentPosition = _currentIndex - _startIndex + 1;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Revision: ${widget.surahName}'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSetupDialog,
            tooltip: 'Change Range',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.withOpacity(0.2),
              const Color(0xFF121212),
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: const Color(0xFF212121),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Revision Progress',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$currentPosition of $totalAyahs',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalAyahs > 0 ? currentPosition / totalAyahs : 0,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content area
            Expanded(
              child: _isFlowRecordingMode
                  ? _buildFlowRecordingView()
                  : _buildPreparationView(),
            ),
            
            // Bottom controls
            if (!_isFlowRecordingMode)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _startFlowRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    icon: const Icon(Icons.mic, size: 28),
                    label: const Text(
                      'Start Flow Recitation',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            
            // Recording controls when in flow recording mode
            if (_isFlowRecordingMode)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Stop flow recording button
                    ElevatedButton.icon(
                      onPressed: _stopFlowRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                    
                    // Next ayah button
                    ElevatedButton.icon(
                      onPressed: _isRecording ? _moveToNextAyahInFlow : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Ayah'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionCard(Map<String, dynamic> ayah) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${ayah['ayahNumber']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Revision',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Show text only if visible
            if (_isTextVisible)
              Text(
                ayah['displayText'] ?? ayah['text'],
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: 'Scheherazade',
                  height: 1.8,
                  color: Colors.black,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              
            const SizedBox(height: 16),
            
            // Status text
            Center(
              child: Text(
                _recordingStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
              
            const SizedBox(height: 16),
              
            // Recording controls
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  ElevatedButton(
                    onPressed: _isPlaying ? null : (_isRecording
                      ? () => _stopRecording(ayah)
                      : () => _startRecording(ayah)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
              
            // API processing status
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _apiResult ?? "Processing recitation...",
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
              
            // Show transcription results if available
            if (_transcriptions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your recitation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTranscriptionWithHighlightedErrors(_transcriptions.last, ayah),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreparationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full range of ayahs in book format
          Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.deepPurple.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ayah ${widget.ayahs[_startIndex]['ayahNumber']} - ${widget.ayahs[_endIndex]['ayahNumber']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review before starting',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Continuous ayahs text in book format
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage('assets/images/paper_texture.png'),
                      fit: BoxFit.cover,
                      opacity: 0.05,
                    ),
                  ),
                  child: Column(
                    children: [
                      RichText(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 24,
                            fontFamily: 'Scheherazade',
                            height: 1.8,
                            color: Colors.black,
                          ),
                          children: List.generate(_endIndex - _startIndex + 1, (index) {
                            final ayahIndex = _startIndex + index;
                            final ayah = widget.ayahs[ayahIndex];
                            
                            return TextSpan(
                              children: [
                                TextSpan(
                                  text: ayah['displayText'] ?? ayah['text'],
                                ),
                                // Add ayah number marker in a circle
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.deepPurple),
                                    ),
                                    child: Text(
                                      '${ayah['ayahNumber']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                ),
                                // Add space between ayahs
                                TextSpan(text: ' '),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // // Central start button
          // Center(
          //   child: ElevatedButton.icon(
          //     onPressed: _startFlowRecording,
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.deepPurple,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(50),
          //       ),
          //       elevation: 5,
          //     ),
          //     icon: const Icon(Icons.mic, size: 28),
          //     label: const Text(
          //       'Start Flow Recitation',
          //       style: TextStyle(fontSize: 18),
          //     ),
          //   ),
          // ),
          
          // const SizedBox(height: 24),
          
          // Instructions moved below start button
          ExpansionTile(
            title: Text(
              'How Flow Recitation Works',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.deepPurple.shade200),
            ),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In this mode, you will recite continuously without pausing between ayahs. The app will:',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      '1. Show one ayah at a time for you to recite',
                      '2. Process your recitation while you continue to the next ayah',
                      '3. Highlight any mistakes in your recitation',
                      '4. If there are mistakes, you\'ll be asked to recite from that ayah again',
                    ].map((text) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
    AyahStatus _getAyahStatus(int ayahIndex) {
    if (_isRecording && ayahIndex == _currentRecitingIndex) {
        return AyahStatus.recording;
    } else if (_isProcessing && _pendingTranscriptions.containsKey(ayahIndex)) {
        return AyahStatus.processing;
    } else if (_correctlyRecitedIndices.contains(ayahIndex)) {
        return AyahStatus.correct;
    } else if (_matchScores.containsKey(ayahIndex) && _matchScores[ayahIndex]! < 70) {
        return AyahStatus.incorrect;
    } else {
        return AyahStatus.initial;
    }
    }

  Widget _buildFlowRecordingView() {
    final currentAyah = widget.ayahs[_currentRecitingIndex];
    final ayahStatus = _getAyahStatus(_currentRecitingIndex);
    
    return Column(
      children: [
        // Current ayah card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Current ayah to recite
                Card(
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _getStatusColor(ayahStatus),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(ayahStatus),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${currentAyah['ayahNumber']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Reciting',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(ayahStatus),
                                  ),
                                ),
                              ],
                            ),
                            _buildStatusIndicator(ayahStatus),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Add a prominent error message when needed
                        if (_errorMessageVisible) 
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 12),
                            padding: EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorFeedback,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Show the ayah text to help them recite correctly this time
                        if (_isTextVisible || ayahStatus == AyahStatus.correct || _errorMessageVisible)
                          Text(
                            currentAyah['displayText'] ?? currentAyah['text'],
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: 'Scheherazade',
                              height: 1.8,
                              color: _errorMessageVisible ? Colors.red.shade900 : Colors.black,
                              backgroundColor: _errorMessageVisible ? Colors.red.shade50 : null,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                          
                        if (!_isTextVisible && ayahStatus != AyahStatus.correct)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: const Center(
                              child: Text(
                                'Recite from memory...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          
                        const SizedBox(height: 16),
                        
                        // Status text
                        Center(
                          child: Text(
                            _getStatusMessage(ayahStatus),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(ayahStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Results section - show ALL previous ayahs with results, most recent first
const SizedBox(height: 20),
Text(
  'Previous Recitations',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.deepPurple,
  ),
),
const SizedBox(height: 12),

// Generate a list of previous ayah indices and reverse it to show most recent first
...List.generate(_currentRecitingIndex - _startIndex, (index) {
  // Reverse the order by calculating index from the end
  final reversedIndex = _currentRecitingIndex - _startIndex - 1 - index;
  final previousAyahIndex = _startIndex + reversedIndex;
  
  // Only display ayahs that have been processed
  if (!_pendingTranscriptions.containsKey(previousAyahIndex)) {
    return SizedBox.shrink();
  }
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: _buildResultCard(previousAyahIndex),
  );
}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add this new method to create result cards for previous ayahs
  Widget _buildResultCard(int ayahIndex) {
    final ayah = widget.ayahs[ayahIndex];
    final hasScore = _matchScores.containsKey(ayahIndex);
    final score = hasScore ? _matchScores[ayahIndex]! : 0;
    final isCorrect = hasScore && score >= 70;
    
    return Card(
      elevation: 2, // Reduced elevation
      margin: EdgeInsets.symmetric(vertical: 4), // Tighter margins
      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Smaller radius
        side: BorderSide(
          color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact header with all elements in one row
            Row(
              children: [
                // Smaller number badge
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${ayah['ayahNumber']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Text takes less space
                Expanded(
                  child: Text(
                    isCorrect ? 'Correct' : 'Needs Improvement',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
                // Score badge is more compact
                if (hasScore)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.red,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '$score%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Use an expandable section for the ayah text
            ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              title: Text(
                'View Ayah Text',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    ayah['displayText'] ?? ayah['text'],
                    style: const TextStyle(
                      fontSize: 16, // Smaller font size
                      fontFamily: 'Scheherazade',
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            
            // Your recitation display
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your recitation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTranscriptionWithHighlightedErrors(
                    _pendingTranscriptions[ayahIndex]!,
                    ayah,
                    textSize: 15, // Smaller text size
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startFlowRecording() async {
    setState(() {
      _isFlowRecordingMode = true;
      _currentRecitingIndex = _startIndex;
      _pendingTranscriptions.clear();
      _matchScores.clear();
      _correctlyRecitedIndices.clear();
      _isTextVisible = false; // Don't show text initially
    });
    
    // Start recording
    await _startRecordingForFlow(widget.ayahs[_currentRecitingIndex]);
  }

  Future<void> _stopFlowRecording() async {
    // Stop any active recording
    if (_isRecording) {
      await _stopRecordingForFlow(widget.ayahs[_currentRecitingIndex]);
    }
    
    setState(() {
      _isFlowRecordingMode = false;
    });
  }

  Future<void> _moveToNextAyahInFlow() async {
    // If we're recording, stop recording and process the current ayah
    if (_isRecording) {
      await _stopRecordingForFlow(widget.ayahs[_currentRecitingIndex]);
    }
    
    // Clear any error states
    setState(() {
      _errorMessageVisible = false;
    });
    
    // Move to next ayah if possible
    if (_currentRecitingIndex < _endIndex) {
      setState(() {
        _currentRecitingIndex++;
        _isTextVisible = false; // Don't show text initially for new ayahs
      });
      
      // Start recording for the next ayah
      await _startRecordingForFlow(widget.ayahs[_currentRecitingIndex]);
    }
  }

  Future<void> _startRecordingForFlow(Map<String, dynamic> ayah) async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _recordingStatus = 'Permission denied for recording';
        });
        return;
      }

      // Hide the text immediately since user has to recite from memory
      setState(() {
        _isTextVisible = false;
      });
      
      final directory = await getTemporaryDirectory();
      String fileName = 'revision_flow_surah_${ayah['surahNumber']}_ayah_${ayah['ayahNumber']}_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = path.join(directory.path, fileName);

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 2,
      );

      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordingPath = filePath;
      });
    } catch (e) {
      setState(() {
        _isTextVisible = true;
      });
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecordingForFlow(Map<String, dynamic> ayah) async {
    try {
      final path = await _audioRecorder.stop();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });

        // Process this ayah asynchronously
        _processAyahRecording(_currentRecitingIndex, path);
      } 
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _processAyahRecording(int ayahIndex, String audioPath) {
    _apiQueue.add(() async {
      final ayah = widget.ayahs[ayahIndex];
      
      // Mark as processing
      setState(() {
        _isProcessing = true;
      });
      
      final File audioFile = File(audioPath);
      final List<int> audioBytes;

      try {
        audioBytes = await audioFile.readAsBytes();
        
        final headers = {
          "Authorization": "Bearer $_apiToken",
          "Content-Type": "audio/wav",
        };
        
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: headers,
          body: audioBytes,
        );
        
        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          String transcription = '';
          
          if (decodedResponse is Map && decodedResponse.containsKey('text')) {
            transcription = decodedResponse['text'];
          } else if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
            transcription = decodedResponse[0]['generated_text'] ?? '';
          }
          
          transcription = _fixArabicEncoding(transcription);
          
          // Calculate match score
          final String originalText = ayah['displayText'] ?? ayah['text'];
          final String cleanOriginal = _prepareTextForComparison(originalText);
          final String cleanTranscription = _prepareTextForComparison(transcription);
          final int matchScore = _calculateMatchScore(cleanTranscription, cleanOriginal);
          
          setState(() {
            _pendingTranscriptions[ayahIndex] = transcription;
            _matchScores[ayahIndex] = matchScore;
            
            if (matchScore >= 70) {
              _correctlyRecitedIndices.add(ayahIndex);
            } else {
              // If incorrect and we've already moved past this ayah, 
              // we need to go back to this ayah with clear feedback
              if (_currentRecitingIndex > ayahIndex) {
                setState(() {
                  _currentRecitingIndex = ayahIndex;
                  _isTextVisible = true; // Show the text to help them correct
                  _errorMessageVisible = true; // Show an error message
                  _errorFeedback = "Please recite this ayah again correctly.";
                });
                
                // Add a short delay before starting recording again to let the user see the message
                Future.delayed(Duration(seconds: 2), () {
                  if (mounted) {
                    _startRecordingForFlow(ayah);
                    
                    // Schedule the error message to disappear
                    Future.delayed(Duration(seconds: 5), () {
                      if (mounted) {
                        setState(() {
                          _errorMessageVisible = false;
                        });
                      }
                    });
                  }
                });
              }
            }
            
            _isProcessing = false;
          });
        } else {
          setState(() {
            _isProcessing = false;
          });
        }
      } catch (e) {
        print('Error processing recording: $e');
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }
}

enum AyahStatus {
  initial,
  recording,
  processing,
  correct,
  incorrect,
}

Color _getStatusColor(AyahStatus status) {
  switch (status) {
    case AyahStatus.initial:
      return Colors.grey;
    case AyahStatus.recording:
      return Colors.blue;
    case AyahStatus.processing:
      return Colors.orange;
    case AyahStatus.correct:
      return Colors.green;
    case AyahStatus.incorrect:
      return Colors.red;
  }
}

String _getStatusMessage(AyahStatus status) {
  switch (status) {
    case AyahStatus.initial:
      return 'Ready to start';
    case AyahStatus.recording:
      return 'Recording... press "Next Ayah" when done';
    case AyahStatus.processing:
      return 'Processing your recitation...';
    case AyahStatus.correct:
      return 'MashaAllah! Correct recitation';
    case AyahStatus.incorrect:
      return 'Needs improvement. Please try again.';
  }
}

Widget _buildStatusIndicator(AyahStatus status) {
  switch (status) {
    case AyahStatus.initial:
      return Icon(Icons.circle_outlined, color: Colors.grey);
    case AyahStatus.recording:
      return Icon(Icons.mic, color: Colors.blue);
    case AyahStatus.processing:
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    case AyahStatus.correct:
      return Icon(Icons.check_circle, color: Colors.green);
    case AyahStatus.incorrect:
      return Icon(Icons.error, color: Colors.red);
  }
}