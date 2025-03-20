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

  @override
  void dispose() {
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
              'assessment': _getAssessmentFromConfidence(tarteelResult.confidence), // Add this helper method
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
              return;
            }
            
            // They agree on what was detected, show the original result
            setState(() {
              _isProcessing = false;
              _analysisResult = result;
              _recordingStatus = 'Analysis complete';
            });
            return;
          }
        } else {
          // For non-problematic letters, trust the model
          setState(() {
            _isProcessing = false;
            _analysisResult = result;
            _recordingStatus = 'Analysis complete';
          });
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

              // Add this after your letter display container
              if (widget.letter != null) ...[
                const SizedBox(height: 20),
                
                // Reference audio button
                ElevatedButton.icon(
                  onPressed: _isRecording || _isProcessing 
                      ? null 
                      : _playReferenceAudio,
                  icon: Icon(
                    _isPlayingReference 
                        ? Icons.stop 
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isPlayingReference 
                        ? 'Stop' 
                        : 'Listen to Correct Pronunciation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlayingReference 
                        ? Colors.orange 
                        : const Color(0xFF00A896),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],

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
