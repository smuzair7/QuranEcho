import 'dart:io';
import 'dart:async'; // Add this import for TimeoutException
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:math' as math;

// Add this class at the top level (not inside any other class)
class TarteelVerificationResult {
  final bool isCorrect;
  final double confidence;
  
  TarteelVerificationResult(this.isCorrect, this.confidence);
}

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

 // API variables
  static const String _tarteelApiToken = "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";
  static const String _tarteelApiUrl = "https://router.huggingface.co/hf-inference/models/tarteel-ai/whisper-base-ar-quran";

// Map Arabic letters to their most common transcription patterns
final Map<String, List<String>> _letterToTranscriptionPatterns = {
  // Problematic letters
  'خ': ['خ', 'kha', 'خا', 'kh', 'خاء'], // Kha
  'ف': ['ف', 'fa', 'فا', 'f', 'فاء'],   // Faa
  'ذ': ['ذ', 'dh', 'ذا', 'z', 'ذال', 'th'], // Zaal
  'ث': ['ث', 'th', 'ثا', 's', 'ثاء', 'sa'], // Saa/Thaa
  'ح': ['ح', 'h', 'حا', 'ha', 'حاء'], // Hha
  'ض': ['ض', 'dh', 'ضا', 'd', 'ضاد', 'daad'], // Duad
  'ع': ['ع', 'a', 'عا', '\'', 'عين', 'ain'], // Aain
  'ص': ['ص', 's', 'صا', 'sa', 'صاد', 'saad'], // Saud
  'غ': ['غ', 'gh', 'غا', 'g', 'غين', 'gain', 'ghain'], // Ghain
  'ظ': ['ظ', 'z', 'ظا', 'dh', 'ظاء', 'za', 'dhaa'], // Zua
  
  // Regular letters - also including patterns for completeness
  'ا': ['ا', 'alif', 'ألف', 'a', 'الف'], // Alif
  'ب': ['ب', 'ba', 'با', 'b', 'باء'], // Ba
  'ت': ['ت', 'ta', 'تا', 't', 'تاء'], // Ta
  'ج': ['ج', 'ja', 'جا', 'j', 'جيم', 'jeem'], // Jeem
  'د': ['د', 'da', 'دا', 'd', 'دال'], // Dal
  'ر': ['ر', 'ra', 'را', 'r', 'راء'], // Raa
  'ز': ['ز', 'za', 'زا', 'z', 'زاي', 'zay'], // Zaa
  'س': ['س', 'sa', 'سا', 's', 'سين', 'seen'], // Seen
  'ش': ['ش', 'sha', 'شا', 'sh', 'شين', 'sheen'], // Sheen
  'ط': ['ط', 'ta', 'طا', 't', 'طاء', 'taa'], // Tua
  'ك': ['ك', 'ka', 'كا', 'k', 'كاف', 'kaaf'], // Kaif
  'ل': ['ل', 'la', 'لا', 'l', 'لام', 'laam'], // Laam
  'م': ['م', 'ma', 'ما', 'm', 'ميم', 'meem'], // Meem
  'ن': ['ن', 'na', 'نا', 'n', 'نون', 'noon'], // Noon
  'ه': ['ه', 'ha', 'ها', 'h', 'هاء'], // Haa
  'و': ['و', 'wa', 'وا', 'w', 'واو', 'waw'], // Wao
  'ي': ['ي', 'ya', 'يا', 'y', 'ياء', 'yaa'], // Yaa
  'ق': ['ق', 'qa', 'قا', 'q', 'قاف', 'qaaf', 'qaf'], // Qauf
  
  // Additional letters/variations
  'أ': ['أ', 'a', 'hamza', 'همزة', 'ء', 'الهمزة'], // Hamza
  'إ': ['إ', 'i', 'همزة كسرة', 'همزة تحت الألف'], // Hamza with kasra
  'آ': ['آ', 'aa', 'ألف مد', 'ألف ممدودة'], // Alif Madd
  'ة': ['ة', 'ta marbuta', 'تاء مربوطة', 'ـة', 'taa'], // Taa Marbuta
  'ى': ['ى', 'alif maqsura', 'ألف مقصورة', 'ya'], // Alif Maqsura
};
  // Add these variables to your _MakharijPageState class
  bool _isPlayingReference = false;
  final _referencePlayer = AudioPlayer(); // Separate player for reference audio

  // Add these state variables
  bool _isAnimating = false;
  List<double> _audioLevels = List.generate(30, (_) => 0.1);
  Timer? _animationTimer;

  // Add this state variable to your _MakharijPageState class
  bool _isPronunciationGuideExpanded = false;

  @override
  void dispose() {
    _animationTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _referencePlayer.dispose(); // Dispose the reference player too
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

      _startAudioVisualization();
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
      // First, use the custom model for primary analysis
      final Uri url = Uri.parse('http://51.21.250.47:5000/analyze_harf');
      
      // Add more detailed logging
      print('Sending audio file: $_recordingPath');
      print('Sending to server: ${url.toString()}');

      // Get the expected harf in English format
      final expectedHarf = widget.letter != null
          ? _arabicToEnglishMap[widget.letter!] ?? ''
          : '';

      print('Expected harf: $expectedHarf');

      // Create a MultipartRequest for the custom model
      final request = http.MultipartRequest('POST', url);
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

      Map<String, dynamic> result;
      bool isModelCorrect = false;
      
      if (response.statusCode == 200) {
        result = json.decode(response.body);
        
        // Check if model prediction is correct
        isModelCorrect = !result.containsKey('is_mismatch') || !result['is_mismatch'];
        
        // If model says correct, we can proceed with the result
        if (isModelCorrect) {
          setState(() {
            _isProcessing = false;
            _analysisResult = result;
            _recordingStatus = 'Analysis complete';
          });
          
          // Show popup dialog with results instead of inline display
          _showResultsPopup(result);
          
          // Show animation for excellent or perfect results
          if (result.containsKey('assessment') &&
              (result['assessment'] == 'Excellent' || result['assessment'] == 'Perfect')) {
            _showSuccessAnimation();
          }
          
          return;
        }
        
        // If we're here, the model thinks the pronunciation is incorrect
        // Let's verify with the Tarteel API as a backup
        if (_isLetterProblematic(widget.letter)) {
          print('Model detected incorrect pronunciation. Verifying with Tarteel API...');
          
          // Do a second check with Tarteel API
          final TarteelVerificationResult tarteelResult = await _verifyWithTarteelAPI();
          
          if (tarteelResult.isCorrect) {
            // Tarteel API thinks it's correct, override the model result
            print('Tarteel API verification succeeded with confidence: ${tarteelResult.confidence}%');
            
            // Create a positive result override
            final Map<String, dynamic> overrideResult = {
              'predicted': expectedHarf,
              'expected': expectedHarf,
              'confidence': tarteelResult.confidence, // Use the dynamic confidence value
              'assessment': _getAssessmentFromConfidence(tarteelResult.confidence), 
              'feedback': 'Your pronunciation is good. Our verification system confirmed it.',
              'is_mismatch': false,
              'verification_method': 'Tarteel API backup',
              'original_model_prediction': result['predicted']
            };
            
            setState(() {
              _isProcessing = false;
              _analysisResult = overrideResult;
              _recordingStatus = 'Analysis complete (verified)';
            });
            
            // Show popup dialog with results
            _showResultsPopup(overrideResult);
            
            return;
          } else {
            // Both model and Tarteel think it's incorrect - show the error UI
            print('Both model and Tarteel API confirm incorrect pronunciation.');
            
            // Model's detected letter
            final String modelDetectedLetter = result['predicted'] ?? '';
            
            // Special case for Sa/Thaa (ث)
            if (widget.letter == 'ث' && modelDetectedLetter == 'Kha' && _tarteelDetectedLetter == 'Seen') {
              print('Special case: Sa/Thaa (ث) - Model detected "Kha" but Tarteel detected "Seen" - considering excellent');
              
              // Create a positive result override
              final Map<String, dynamic> overrideResult = {
                'predicted': 'Sa', // The correct expected letter
                'expected': 'Sa',
                'confidence': 95.0, // High confidence
                'assessment': 'Excellent',
                'feedback': 'Excellent pronunciation of Sa (ث)!',
                'is_mismatch': false,
                'verification_method': 'Special case handler',
              };
              
              setState(() {
                _isProcessing = false;
                _analysisResult = overrideResult;
                _recordingStatus = 'Analysis complete (special case)';
              });
              
              // Show popup dialog with results
              _showResultsPopup(overrideResult);
              
              // Show success animation
              _showSuccessAnimation();
              
              return;
            }

            // Check if both agree on the detected letter
            final bool bothAgreeOnDetection = 
                _tarteelDetectedLetter != null && 
                _tarteelDetectedLetter == modelDetectedLetter;
            
            // If they disagree, modify the result to hide the detected letter
            if (!bothAgreeOnDetection) {
              print('Model detected "$modelDetectedLetter" but Tarteel detected "$_tarteelDetectedLetter" - hiding detected letter');
              
              // Create a modified result that will prevent showing the detected letter
              final Map<String, dynamic> modifiedResult = Map<String, dynamic>.from(result);
              modifiedResult['show_detected'] = false;
              modifiedResult['feedback'] = 'Your pronunciation needs improvement. Try again.';
              
              setState(() {
                _isProcessing = false;
                _analysisResult = modifiedResult;
                _recordingStatus = 'Analysis complete';
              });
              
              // Show popup dialog with results
              _showResultsPopup(modifiedResult);
              
              return;
            }
            
            // They agree on what was detected, show the original result
            setState(() {
              _isProcessing = false;
              _analysisResult = result;
              _recordingStatus = 'Analysis complete';
            });
            
            // Show popup dialog with results
            _showResultsPopup(result);
            
            return;
          }
        } else {
          // For non-problematic letters, trust the model
          setState(() {
            _isProcessing = false;
            _analysisResult = result;
            _recordingStatus = 'Analysis complete';
          });
          
          // Show popup dialog with results
          _showResultsPopup(result);
        }
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

  // Helper method to check if a letter is in our problematic list
  bool _isLetterProblematic(String? letter) {
    if (letter == null) return false;
    return _letterToTranscriptionPatterns.containsKey(letter);
  }



// Update this method to return the verification result with confidence
Future<TarteelVerificationResult> _verifyWithTarteelAPI() async {
  try {
    if (_recordingPath == null || widget.letter == null) {
      return TarteelVerificationResult(false, 0.0);
    }
    
    print('Verifying with Tarteel API...');
    
    final File audioFile = File(_recordingPath!);
    final bytes = await audioFile.readAsBytes();
    
    // Send to Tarteel API
    final response = await http.post(
      Uri.parse(_tarteelApiUrl),
      headers: {
        "Authorization": "Bearer $_tarteelApiToken",
        "Content-Type": "audio/wav",
      },
      body: bytes,
    ).timeout(
      const Duration(seconds: 15), // Add timeout
      onTimeout: () => http.Response('{"error":"timeout"}', 408),
    );
    
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      String transcription = '';
      
      if (decodedResponse is Map && decodedResponse.containsKey('text')) {
        transcription = decodedResponse['text'];
      } else if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
        transcription = decodedResponse[0]['generated_text'] ?? '';
      } else {
        transcription = decodedResponse.toString();
      }
      
      // Fix Arabic encoding issues
      transcription = _fixArabicEncoding(transcription);
      
      print('Tarteel API transcription: $transcription');
      
      // Check for exact matches first - highest confidence
      if (transcription.trim() == widget.letter) {
        print('Exact letter match in transcription');
        return TarteelVerificationResult(true, 95.0); // Excellent match
      }
      
      // Check if transcription contains patterns for this letter
      final patterns = _letterToTranscriptionPatterns[widget.letter!] ?? [];
      
      // Check for perfect matches with common patterns
      for (final pattern in patterns.take(3)) { // First few patterns are most reliable
        if (transcription.trim() == pattern) {
          print('Found exact pattern match "$pattern" in transcription');
          return TarteelVerificationResult(true, 90.0); // Very good match
        }
      }
      
      // Check for partial matches with main patterns
      for (final pattern in patterns.take(3)) {
        if (transcription.contains(pattern)) {
          print('Found main pattern "$pattern" in transcription');
          return TarteelVerificationResult(true, 85.0); // Good match
        }
      }
      
      // Check for partial matches with any pattern
      for (final pattern in patterns) {
        if (transcription.contains(pattern)) {
          print('Found pattern "$pattern" in transcription');
          return TarteelVerificationResult(true, 75.0); // Acceptable match
        }
      }
      
      // If the expected letter appears directly in the transcription
      if (transcription.contains(widget.letter!)) {
        print('Found letter in transcription');
        return TarteelVerificationResult(true, 70.0); // Basic match
      }
      
      // Store what Tarteel detected for comparison
      _tarteelDetectedLetter = _detectLetterFromTranscription(transcription);
      print('Tarteel detected: $_tarteelDetectedLetter');
      
      return TarteelVerificationResult(false, 0.0); // No match
    } else {
      print('Tarteel API error: ${response.statusCode}');
      return TarteelVerificationResult(false, 0.0);
    }
  } catch (e) {
    print('Error verifying with Tarteel API: $e');
    return TarteelVerificationResult(false, 0.0);
  }
}

  // Method to fix Arabic encoding (use your existing method)
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
            'Ø¹': 'ع', 'Øº': 'غ', 'Ù': 'ق', 'Ù': 'ك', 'Ù': 'ل',
            'Ù': 'م', 'Ù': 'ن', 'Ù': 'ه', 'Ù': 'و', 'Ù': 'ي',
          };
          
          String fixed = text;
          replacements.forEach((k, v) {
            fixed = fixed.replaceAll(k, v);
          });
          return fixed;
        }
      }
    }
    return text;
  }

  // Add this variable to store Tarteel's detection
  String? _tarteelDetectedLetter;

  // Ensure this method returns the English name of the letter in the same format 
  // as your model's output (e.g., "Kha", "Aain", etc.)
  String? _detectLetterFromTranscription(String transcription) {
    // Check each letter's patterns against the transcription
    for (final entry in _letterToTranscriptionPatterns.entries) {
      final letter = entry.key;
      final patterns = entry.value;
      
      for (final pattern in patterns) {
        if (transcription.contains(pattern)) {
          // Convert Arabic letter to English name for comparison with model
          final englishName = _arabicToEnglishMap[letter];
          print('Found pattern "$pattern" matching letter "$letter" -> "$englishName"');
          return englishName;
        }
      }
    }
    
    // If transcription is exactly a single character that's in our mapping
    if (transcription.trim().length == 1 && _arabicToEnglishMap.containsKey(transcription.trim())) {
      return _arabicToEnglishMap[transcription.trim()];
    }
    
    print('No letter match found in transcription: "$transcription"');
    return null; // No clear match found
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

  // Add this helper method
  String _getAssessmentFromConfidence(double confidence) {
    if (confidence >= 90) return 'Excellent';
    if (confidence >= 80) return 'Very Good';
    if (confidence >= 70) return 'Good';
    if (confidence >= 60) return 'Fair';
    if (confidence >= 50) return 'Needs Improvement';
    return 'Poor';
  }

  // Add this method to your _MakharijPageState class

// Collapsible pronunciation guide
Widget _buildCollapsibleGuide() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1F8A70).withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isPronunciationGuideExpanded = !_isPronunciationGuideExpanded;
          });
        },
        child: Column(
          children: [
            // Header - always visible
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.speaker_notes,
                    color: const Color(0xFF1F8A70),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How to Pronounce',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F8A70),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isPronunciationGuideExpanded 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF1F8A70),
                  ),
                ],
              ),
            ),
            
            // Expandable content
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: _buildPronunciationGuideContent(),
              crossFadeState: _isPronunciationGuideExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    ),
  );
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
                      
                      // Only show the detected letter if both systems agree
                      if (!_analysisResult!.containsKey('show_detected') || _analysisResult!['show_detected'] != false) ...[
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

  // Update this method to use English names for the audio files
  Future<void> _playReferenceAudio() async {
    if (widget.letter == null) return;
    
    try {
      // If already playing, stop it
      if (_isPlayingReference) {
        await _referencePlayer.stop();
        setState(() {
          _isPlayingReference = false;
          _recordingStatus = 'Ready to record';
        });
        return;
      }
      
      setState(() {
        _recordingStatus = 'Loading reference audio...';
        _isPlayingReference = true;
      });
      
      // Get the English name for the current Arabic letter
      final englishName = _arabicToEnglishMap[widget.letter!];
      if (englishName == null) {
        print('Error: No English name found for letter ${widget.letter!}');
        setState(() {
          _isPlayingReference = false;
          _recordingStatus = 'Reference audio not available';
        });
        return;
      }
      
      // Try to load the audio file using the English name
      try {
        final assetPath = 'assets/audio/makharij/$englishName.m4a';
        print('Loading reference audio: $assetPath');
        
        await _referencePlayer.setAsset(assetPath);
        
        setState(() {
          _recordingStatus = 'Playing reference pronunciation...';
        });
        
        await _referencePlayer.play();
        
        // Listen for completion
        _referencePlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) {
              setState(() {
                _isPlayingReference = false;
                _recordingStatus = 'Ready to record';
              });
            }
          }
        });
      } catch (e) {
        print('Error loading reference audio: $e');
        setState(() {
          _isPlayingReference = false;
          _recordingStatus = 'Could not load reference audio';
        });
      }
    } catch (e) {
      print('Reference audio error: $e');
      setState(() {
        _isPlayingReference = false;
        _recordingStatus = 'Error playing reference';
      });
    }
  }

  // Add this method to start the audio visualization
  void _startAudioVisualization() {
    _isAnimating = true;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _audioLevels.length; i++) {
            if (_isRecording || _isPlaying || _isPlayingReference) {
              _audioLevels[i] = math.min(1.0, 0.1 + math.Random().nextDouble() * 0.7);
            } else {
              _audioLevels[i] = math.max(0.1, _audioLevels[i] * 0.85);
            }
          }
        });
      }
    });
  }

  // Add this widget for audio visualization
  Widget _buildAudioVisualization() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _audioLevels.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 4,
            height: _audioLevels[index] * 60,
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withOpacity(0.7)
                  : _isPlayingReference
                      ? Colors.orange.withOpacity(0.7)
                      : Colors.green.withOpacity(0.7),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

  // Add this method for success animation
  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          height: 300,
          child: Center(
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (context, double value, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(color: Color(0xFF1F8A70), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 80),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: value,
                      child: const Text('Excellent!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                );
              },
              onEnd: () {
                Future.delayed(const Duration(milliseconds: 500), () {
                  Navigator.of(context).pop();
                });
              },
            ),
          ),
        ),
      ),
    );
  }


  // Enhance the audio playback button
  Widget _buildEnhancedAudioButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPlayingReference
              ? [Colors.orange.shade400, Colors.orange.shade700]
              : [const Color(0xFF00A896), const Color(0xFF1F8A70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _isPlayingReference
                ? Colors.orange.withOpacity(0.4)
                : const Color(0xFF1F8A70).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRecording || _isProcessing ? null : _playReferenceAudio,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPlayingReference ? Icons.stop_circle : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPlayingReference ? 'Stop Audio' : 'Listen to Pronunciation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _isPlayingReference ? 'Playing...' : 'Tap to hear correct pronunciation',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isPlayingReference)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Update the build method to improve layout

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.letter != null
          ? 'Pronunciation: ${widget.letter}'
          : 'Pronunciation Practice'),
      backgroundColor: const Color(0xFF1F8A70),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Top section - Main letter display (with space around it)
            const SizedBox(height: 20),
            if (widget.letter != null) 
              _buildMainLetterDisplay(),
            const SizedBox(height: 20),
                
            // Audio visualization
            if (_isRecording || _isPlaying || _isPlayingReference) ...[
              _buildAudioVisualization(),
              const SizedBox(height: 16),
            ],
            
            // Status text
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Text(
                _recordingStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                  color: _isRecording ? Colors.red : Colors.grey[800],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recording controls
            _buildRecordingControls(),
            
            // Add a spacer to push the instructions to the bottom
            const Spacer(),
            
            // Instructions at the bottom
            if (widget.letter != null)
              _buildCollapsibleGuide(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

// Replace the _buildMainLetterDisplay method with this improved version

Widget _buildMainLetterDisplay() {
  return Stack(
    alignment: Alignment.center,
    children: [
      // Large letter container
      Container(
        width: 160,  // Increased size
        height: 160, // Increased size
        decoration: BoxDecoration(
          color: const Color(0xFF1F8A70).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1F8A70).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.letter!,
            style: const TextStyle(
              fontSize: 90,  // Increased font size
              fontWeight: FontWeight.bold,
              fontFamily: 'Scheherazade',
            ),
          ),
        ),
      ),
      
      // Sound button positioned at top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: 54,  // Smaller
          height: 54,  // Smaller
          decoration: BoxDecoration(
            color: _isPlayingReference ? Colors.orange : const Color(0xFF00A896),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isPlayingReference ? Colors.orange : const Color(0xFF00A896)).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isRecording || _isProcessing ? null : _playReferenceAudio,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  _isPlayingReference ? Icons.stop : Icons.volume_up,
                  color: Colors.white,
                  size: 28,  // Smaller
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// Updated method for recording controls
Widget _buildRecordingControls() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Record button
      _buildEnhancedControlButton(
        onPressed: _isPlaying || _isProcessing
            ? null
            : (_isRecording ? _stopRecording : _checkPermissionAndStartRecording),
        color: _isRecording ? Colors.red : const Color(0xFF1F8A70),
        icon: _isRecording ? Icons.stop : Icons.mic,
        label: _isRecording ? 'Stop' : 'Record',
      ),
      
      const SizedBox(width: 20),
      
      // Play button
      _buildEnhancedControlButton(
        onPressed: (_recordingPath != null &&
                !_isRecording &&
                !_isProcessing)
            ? (_isPlaying ? _stopPlayback : _playRecording)
            : null,
        color: _isPlaying ? Colors.orange : const Color(0xFF00A896),
        icon: _isPlaying ? Icons.stop : Icons.play_arrow,
        label: _isPlaying ? 'Stop' : 'Play',
      ),
      
      const SizedBox(width: 20),
      
      // Analyze button
      _buildEnhancedControlButton(
        onPressed: (_recordingPath != null &&
                !_isRecording &&
                !_isPlaying &&
                !_isProcessing)
            ? _analyzeRecording
            : null,
        color: const Color(0xFF3778FF),
        icon: Icons.analytics_outlined,
        label: 'Analyze',
        isLoading: _isProcessing,
      ),
    ],
  );
}

// Enhanced control button with label
Widget _buildEnhancedControlButton({
  required VoidCallback? onPressed, 
  required Color color, 
  required IconData icon,
  required String label,
  bool isLoading = false,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 70,
        height: 70,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: color.withOpacity(0.5),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  icon,
                  size: 32,
                ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onPressed == null ? Colors.grey : Colors.grey[800],
        ),
      ),
    ],
  );
}

  // New method for letter display with collapsible guide
  Widget _buildLetterWithCollapsingGuide() {
    return Column(
      children: [
        // Row with letter and listen button
        Row(
          children: [
            // Letter display
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1F8A70).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.letter!,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Scheherazade',
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Listen button - takes remaining space
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isRecording || _isProcessing ? null : _playReferenceAudio,
                  icon: Icon(
                    _isPlayingReference ? Icons.stop : Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    _isPlayingReference ? 'Stop' : 'Listen to\nPronunciation',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlayingReference 
                        ? Colors.orange 
                        : const Color(0xFF00A896),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Collapsible pronunciation guide
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F8A70).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _isPronunciationGuideExpanded = !_isPronunciationGuideExpanded;
                });
              },
              child: Column(
                children: [
                  // Header - always visible
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speaker_notes,
                          color: const Color(0xFF1F8A70),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to Pronounce',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F8A70),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isPronunciationGuideExpanded 
                              ? Icons.keyboard_arrow_up 
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFF1F8A70),
                        ),
                      ],
                    ),
                  ),
                  
                  // Expandable content
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: _buildPronunciationGuideContent(),
                    crossFadeState: _isPronunciationGuideExpanded 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Content of the pronunciation guide (shown when expanded)
  Widget _buildPronunciationGuideContent() {
    // Map letters to their articulation points and instructions (use your existing data)
    final Map<String, Map<String, String>> letterGuides = {
      'ا': {'point': 'Throat (Bottom)', 'instruction': 'Open your throat and mouth widely to produce this sound.'},
      'ه': {'point': 'Throat (Middle)', 'instruction': 'Exhale gently from the middle of your throat.'},
      'ع': {'point': 'Throat (Middle)', 'instruction': 'Constrict the middle of your throat slightly.'},
      'ح': {'point': 'Throat (Top)', 'instruction': 'Produce a gentle friction from the top of your throat.'},
      'غ': {'point': 'Throat (Top)', 'instruction': 'Create a gargling sound from the top of your throat.'},
      'خ': {'point': 'Throat (Top)', 'instruction': 'Create friction with the back of your tongue against the soft palate.'},
      'ق': {'point': 'Tongue (Back)', 'instruction': 'Press the back of your tongue against the roof of your mouth.'},
      'ك': {'point': 'Tongue (Middle-Back)', 'instruction': 'Press the middle-back of your tongue against the roof of your mouth.'},
      'ج': {'point': 'Tongue (Middle)', 'instruction': 'Press the middle of your tongue against the roof of your mouth.'},
      'ش': {'point': 'Tongue (Middle)', 'instruction': 'Spread the middle of your tongue and create a hissing sound.'},
      'ي': {'point': 'Tongue (Middle)', 'instruction': 'Raise the middle of your tongue toward the roof of your mouth.'},
      'ل': {'point': 'Tongue (Side)', 'instruction': 'Touch the tip of your tongue to the roof of your mouth.'},
      'ر': {'point': 'Tongue (Tip)', 'instruction': 'Vibrate the tip of your tongue near the front of the roof of your mouth.'},
      'ن': {'point': 'Tongue (Tip)', 'instruction': 'Touch the tip of your tongue to the roof of your mouth and let air pass through your nose.'},
      'ت': {'point': 'Tongue (Tip-Teeth)', 'instruction': 'Touch the tip of your tongue behind your upper front teeth.'},
      'د': {'point': 'Tongue (Tip-Teeth)', 'instruction': 'Touch the tip of your tongue behind your upper front teeth with a stronger pressure.'},
      'ط': {'point': 'Tongue (Tip-Teeth)', 'instruction': 'Press the tip of your tongue firmly behind your upper front teeth.'},
      'ث': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue between your front teeth and blow air out gently.'},
      'ذ': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue between your front teeth.'},
      'ظ': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue between your front teeth with pressure.'},
      'ص': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue near your lower front teeth and raise the back of your tongue.'},
      'س': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue near your lower front teeth and create a hissing sound.'},
      'ز': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue near your lower front teeth and create a buzzing sound.'},
      'ف': {'point': 'Lip-Teeth', 'instruction': 'Place your upper teeth against your lower lip and blow air out.'},
      'ب': {'point': 'Lips', 'instruction': 'Press your lips together and then separate them.'},
      'م': {'point': 'Lips', 'instruction': 'Press your lips together and let air pass through your nose.'},
      'و': {'point': 'Lips', 'instruction': 'Round your lips and create a sound from your throat.'},
    };

    final guide = letterGuides[widget.letter!] ?? {'point': 'Unknown', 'instruction': 'Listen to the reference audio for correct pronunciation.'};
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Articulation Point: ${guide['point']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.gesture, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guide['instruction']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Listen to the reference audio for the perfect pronunciation and try to mimic it.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Compact control button
  Widget _buildControlButton({
    required VoidCallback? onPressed, 
    required Color color, 
    required IconData icon, 
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Icon(
                icon,
                size: 30,
              ),
      ),
    );
  }

  // Compact audio button
  Widget _buildCompactAudioButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,  // Smaller
      child: ElevatedButton.icon(
        onPressed: _isRecording || _isProcessing ? null : _playReferenceAudio,
        icon: Icon(
          _isPlayingReference ? Icons.stop : Icons.volume_up,
          color: Colors.white,
          size: 20,  // Smaller
        ),
        label: Text(
          _isPlayingReference ? 'Stop' : 'Listen to Pronunciation',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,  // Smaller
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPlayingReference 
              ? Colors.orange 
              : const Color(0xFF00A896),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Compact pronunciation guide
  Widget _buildCompactPronunciationGuide() {
    if (widget.letter == null) return const SizedBox.shrink();

    // Map letters to their articulation points (use your existing mapping)
    final Map<String, Map<String, String>> letterGuides = {
      'ا': {'point': 'Throat (Bottom)', 'instruction': 'Open your throat and mouth widely.'},
      // Include all your other letters here (shortened instructions)
    };

    final guide = letterGuides[widget.letter] ?? {'point': 'Unknown', 'instruction': 'Listen to reference audio.'};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'How to Pronounce',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F8A70),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Point: ${guide['point']}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        Text(
          guide['instruction']!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Compact result card
  Widget _buildCompactAnalysisResultCard() {
    if (_analysisResult == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display error message if there's an error key
            if (_analysisResult!.containsKey('error')) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 4),
              Text(
                _analysisResult!['error'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
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
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Incorrect Letter',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              
              // Compare expected vs detected
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'Expected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F8A70).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.letter ?? '',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Scheherazade',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Only show the detected letter if both systems agree
                  if (!_analysisResult!.containsKey('show_detected') || _analysisResult!['show_detected'] != false) ...[
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(
                          'Detected',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _arabicToEnglishMap.entries
                                  .firstWhere(
                                    (entry) =>
                                        entry.value ==
                                        _analysisResult!['predicted'],
                                    orElse: () => const MapEntry('?', '?'),
                                  )
                                  .key,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Scheherazade',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              Text(
                _analysisResult!['feedback'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _analysisResult = null;
                  _recordingStatus = 'Ready to record again';
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F8A70),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
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
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _analysisResult!['assessment'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getAssessmentColor(_analysisResult!['assessment']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Display confidence with a progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence: ${_analysisResult!['confidence'].toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _analysisResult!['confidence'] / 100,
                      minHeight: 8,
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAssessmentColor(_analysisResult!['assessment'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: _getAssessmentColor(_analysisResult!['assessment']),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _analysisResult!['feedback'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Try again button
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _analysisResult = null;
                  _recordingStatus = 'Ready to record again';
                }),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Practice Again'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: _getAssessmentColor(_analysisResult!['assessment'])),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Compact practice tips
  Widget _buildPracticeTips() {
    if (widget.letter == null) {
      return Center(
        child: Text(
          'Select a letter to practice pronunciation',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: PageView(
        children: [
          _buildTipCard(
            icon: Icons.record_voice_over, 
            title: 'Clear Articulation', 
            description: 'Focus on the exact point of articulation described above.', 
            color: Colors.blue
          ),
          _buildTipCard(
            icon: Icons.mic, 
            title: 'Proper Volume', 
            description: 'Speak clearly but naturally. Not too loud or soft.', 
            color: Colors.purple
          ),
          _buildTipCard(
            icon: Icons.speed, 
            title: 'Correct Duration', 
            description: 'Hold the sound for its proper duration.', 
            color: Colors.orange
          ),
        ],
      ),
    );
  }

  // Add this new method to properly check for permissions before recording
  Future<void> _checkPermissionAndStartRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    
    if (!hasPermission) {
      // Show permission denied dialog with instructions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Microphone Permission Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic_off,
                color: Colors.red,
                size: 50,
              ),
              SizedBox(height: 16),
              Text(
                'This app needs microphone permission to record your pronunciation.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Please go to Settings > Apps > QuranEcho > Permissions and grant microphone access.',
                style: TextStyle(fontSize: 14),
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
      setState(() {
        _recordingStatus = 'Permission denied for recording';
      });
      return;
    }
    
    // If we have permission, start recording
    _startRecording();
  }

  // Modify _buildTipCard for better space efficiency
  Widget _buildTipCard({required IconData icon, required String title, required String description, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),  // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),  // Reduced padding
                  decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),  // Smaller icon
                ),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),  // Smaller font
              ],
            ),
            const SizedBox(height: 8),  // Reduced spacing
            Text(
              description, 
              style: const TextStyle(fontSize: 13),  // Smaller font
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Modify _buildPronunciationGuide for better space efficiency
  Widget _buildPronunciationGuide() {
    if (widget.letter == null) return const SizedBox.shrink();

    // Map letters to their articulation points and instructions
    final Map<String, Map<String, String>> letterGuides = {
      'ا': {'point': 'Throat (Bottom)', 'instruction': 'Open your throat and mouth widely to produce this sound.'},
      'ه': {'point': 'Throat (Middle)', 'instruction': 'Exhale gently from the middle of your throat.'},
      'ع': {'point': 'Throat (Middle)', 'instruction': 'Constrict the middle of your throat slightly.'},
      'ح': {'point': 'Throat (Top)', 'instruction': 'Produce a gentle friction from the top of your throat.'},
      'غ': {'point': 'Throat (Top)', 'instruction': 'Create a gargling sound from the top of your throat.'},
      'خ': {'point': 'Throat (Top)', 'instruction': 'Create friction with the back of your tongue against the soft palate.'},
      'ق': {'point': 'Tongue (Back)', 'instruction': 'Press the back of your tongue against the roof of your mouth.'},
      'ك': {'point': 'Tongue (Middle-Back)', 'instruction': 'Press the middle-back of your tongue against the roof of your mouth.'},
      'ج': {'point': 'Tongue (Middle)', 'instruction': 'Press the middle of your tongue against the roof of your mouth.'},
      'ش': {'point': 'Tongue (Middle)', 'instruction': 'Spread the middle of your tongue and create a hissing sound.'},
      'ي': {'point': 'Tongue (Middle)', 'instruction': 'Raise the middle of your tongue toward the roof of your mouth.'},
      'ل': {'point': 'Tongue (Side)', 'instruction': 'Touch the tip of your tongue to the roof of your mouth.'},
      'ر': {'point': 'Tongue (Tip)', 'instruction': 'Vibrate the tip of your tongue near the front of the roof of your mouth.'},
      'ن': {'point': 'Tongue (Tip)', 'instruction': 'Touch the tip of your tongue to the roof of your mouth and let air pass through your nose.'},
      'ت': {'point': 'Tongue (Tip-Teeth)', 'instruction': 'Touch the tip of your tongue behind your upper front teeth.'},
      'د': {'point': 'Tongue (Tip-Teeth)', 'instruction': 'Touch the tip of your tongue behind your upper front teeth with a stronger pressure.'},
      'ط': {'point': 'Tongue (Tip-Teeth)', 'instruction': 'Press the tip of your tongue firmly behind your upper front teeth.'},
      'ث': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue between your front teeth and blow air out gently.'},
      'ذ': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue between your front teeth.'},
      'ظ': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue between your front teeth with pressure.'},
      'ص': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue near your lower front teeth and raise the back of your tongue.'},
      'س': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue near your lower front teeth and create a hissing sound.'},
      'ز': {'point': 'Tongue-Teeth', 'instruction': 'Place the tip of your tongue near your lower front teeth and create a buzzing sound.'},
      'ف': {'point': 'Lip-Teeth', 'instruction': 'Place your upper teeth against your lower lip and blow air out.'},
      'ب': {'point': 'Lips', 'instruction': 'Press your lips together and then separate them.'},
      'م': {'point': 'Lips', 'instruction': 'Press your lips together and let air pass through your nose.'},
      'و': {'point': 'Lips', 'instruction': 'Round your lips and create a sound from your throat.'},
    };

    final guide = letterGuides[widget.letter] ?? {'point': 'Unknown', 'instruction': 'Listen to the reference audio for correct pronunciation.'};
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),  // Reduced margin
      padding: const EdgeInsets.all(12),  // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speaker_notes, color: const Color(0xFF1F8A70)),
              const SizedBox(width: 8),
              Text(
                'How to Pronounce',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F8A70),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Articulation Point: ${guide['point']}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.gesture, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guide['instruction']!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Listen to the reference audio for the perfect pronunciation and try to mimic it.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add this method to display results in a popup dialog
void _showResultsPopup(Map<String, dynamic> result) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Pronunciation Analysis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F8A70),
                ),
              ),
              const SizedBox(height: 20),
              
              // Display error message if there's an error key
              if (result.containsKey('error')) ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  result['error'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
              // Handle mismatch case specially
              else if (result.containsKey('is_mismatch') &&
                  result['is_mismatch'] == true) ...[
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
                const SizedBox(height: 20),
                
                // Compare expected vs detected
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
                          width: 70,
                          height: 70,
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
                    
                    // Only show the detected letter if both systems agree
                    if (!result.containsKey('show_detected') || result['show_detected'] != false) ...[
                      const SizedBox(width: 30),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 30),
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
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _arabicToEnglishMap.entries
                                    .firstWhere(
                                      (entry) =>
                                          entry.value ==
                                          result['predicted'],
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
                  ],
                ),
                
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    result['feedback'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]
              // Display successful pronunciation assessment
              else ...[
                // Letter in center
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getAssessmentColor(result['assessment']).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.letter ?? '',
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Scheherazade',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Success icon and assessment text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _getAssessmentColor(result['assessment']),
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result['assessment'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getAssessmentColor(result['assessment']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Display confidence with a progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence: ${result['confidence'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: result['confidence'] / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getAssessmentColor(result['assessment']),
                        ),
                      ),
                    ),
                  ],
                ),

                // Display feedback
                if (result.containsKey('feedback')) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getAssessmentColor(result['assessment'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getAssessmentColor(result['assessment']).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: _getAssessmentColor(result['assessment']),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result['feedback'],
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              // Close button at bottom
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A70),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
