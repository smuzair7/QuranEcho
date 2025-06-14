import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:queue/queue.dart';
import 'dart:math' as math;
import 'package:quran_echo/pages/revision_page.dart';
import 'package:provider/provider.dart';
import 'package:quran_echo/services/user_stats_service.dart';
import 'package:quran_echo/services/user_provider.dart';

class HifzPage extends StatefulWidget {
  const HifzPage({super.key});

  @override
  State<HifzPage> createState() => _HifzPageState();
}

class _HifzPageState extends State<HifzPage> {
  // Surah info variables
  int? surahNumber;
  String? surahName;
  String? arabicName;
  int? ayahCount;
  // Add these to your existing state variables
  bool _isPracticingCurrentAyah = false;
  // Audio recording variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start recording';

  // API variables
  static const String _apiToken = "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";
  static const String _apiUrl =
      "https://vb1pti1yhtwgtlth.us-east-1.aws.endpoints.huggingface.cloud";
  bool _isProcessing = false;
  String? _apiResult;
  List<String> _transcriptions = [];

  // Queue for API requests
  final Queue _apiQueue = Queue();

  // Ayah display related variables
  List<Map<String, dynamic>> ayahs = [];
  bool isLoading = true;
  String errorMessage = '';

  // Currently practicing ayah
  Map<String, dynamic>? _currentAyah;
  bool _isPracticingAyah = false;

  // Practice session variables
  int _currentAyahIndex = 0;
  bool _hasVerifiedCurrentAyah = false;
  bool _isReviewMode = false;
  List<int> _memorizedAyahIndices = [];

  // Text visibility during recording
  bool _isTextVisible = true;

  // User stats variables
  final UserStatsService _userStatsService = UserStatsService();
  bool _didCompleteSurah = false;
  DateTime? _sessionStartTime;
  int _newlyMemorizedAyahs = 0;

  @override
  void initState() {
    super.initState();
    _loadSurahContent();
    // Initialize session start time when the page loads
    _sessionStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSurahContent() async {
    try {
      final String jsonData =
          await rootBundle.loadString('assets/data/quran.json');
      final Map<String, dynamic> quranData = json.decode(jsonData);

      // Get surah number from arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        surahNumber = args['surahNumber'];
        surahName = args['surahName'];
        arabicName = args['arabicName'];
        ayahCount = args['ayahCount'];
      }

      if (surahNumber == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Unable to identify surah';
        });
        return;
      }

      // Get the selected surah data
      final Map<String, dynamic>? surahData = quranData[surahNumber.toString()];

      if (surahData == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Surah data not found';
        });
        return;
      }

      // Parse ayah data
      final List<Map<String, dynamic>> parsedAyahs = [];
      surahData.forEach((ayahNumber, ayahData) {
        parsedAyahs.add({
          'surahNumber': surahNumber,
          'ayahNumber': int.parse(ayahNumber),
          'text': ayahData['text'], // Plain text without diacritics
          'displayText':
              ayahData['displayText'], // Text with diacritics for display
          'hasRecording': false,
          'recordingPath': null,
        });
      });

      // Sort ayahs by ayah number
      parsedAyahs.sort((a, b) => a['ayahNumber'].compareTo(b['ayahNumber']));

      setState(() {
        ayahs = parsedAyahs;
        isLoading = false;
        _currentAyah =
            ayahs.isNotEmpty ? ayahs[0] : null; // Initialize the first ayah
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading surah content: $e';
      });
    }
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
      String fileName =
          'surah_${ayah['surahNumber']}_ayah_${ayah['ayahNumber']}_${DateTime.now().millisecondsSinceEpoch}.wav';
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

          // Update ayah in list with recording path
          final index = ayahs.indexWhere((a) =>
              a['surahNumber'] == ayah['surahNumber'] &&
              a['ayahNumber'] == ayah['ayahNumber']);

          if (index >= 0) {
            ayahs[index]['hasRecording'] = true;
            ayahs[index]['recordingPath'] = path;
          }
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
          } else if (decodedResponse is List &&
              decodedResponse.isNotEmpty &&
              decodedResponse[0] is Map) {
            text = decodedResponse[0]['generated_text'] ?? '';
          } else {
            text = decodedResponse.toString();
          }

          text = _fixArabicEncoding(text);

          setState(() {
            _isProcessing = false;
            _transcriptions.add(text);
            _apiResult =
                "Successfully processed audio with Tarteel AI Quran model";
          });

          success = true;
          break;
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          currentRetry++;
        } else {
          setState(() {
            _isProcessing = false;
            _apiResult =
                "API Error ${response.statusCode}\n${response.reasonPhrase}\n\nPlease check your API token or try another model.";
          });
          break;
        }
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          setState(() {
            _isProcessing = false;
            _apiResult =
                "Error processing audio after $maxRetries attempts: ${e.toString()}";
          });
        }
      }
    }

    if (!success && currentRetry >= maxRetries) {
      setState(() {
        _isProcessing = false;
        _apiResult =
            "API failed to respond after $maxRetries attempts. The model may still be loading. Please try again in a minute.";
      });
    }

    if (success) {
      // Check transcription against original text
      _verifyRecitationAndProgress();
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
          final bytes =
              text.codeUnits.map((c) => c < 128 ? c : (c - 848)).toList();
          return String.fromCharCodes(bytes);
        } catch (e2) {
          // Fall back to manual replacement
          final Map<String, String> replacements = {
            'Ø§': 'ا',
            'Ø£': 'أ',
            'Ø¢': 'آ',
            'Ø¥': 'إ',
            'Ø¨': 'ب',
            'Øª': 'ت',
            'Ø«': 'ث',
            'Ø¬': 'ج',
            'Ø­': 'ح',
            'Ø®': 'خ',
            'Ø¯': 'د',
            'Ø°': 'ذ',
            'Ø±': 'ر',
            'Ø²': 'ز',
            'Ø³': 'س',
            'Ø´': 'ش',
            'Øµ': 'ص',
            'Ø¶': 'ض',
            'Ø·': 'ط',
            'Ø¸': 'ظ',
            'Ø¹': 'ع',
            'Øº': 'غ',
            'Ù': 'ف',
            'Ù‚': 'ق',
            'Ùƒ': 'ك',
            'Ù„': 'ل',
            'Ù…': 'م',
            'Ù†': 'ن',
            'Ù‡': 'ه',
            'Ùˆ': 'و',
            'ÙŠ': 'ي',
            'Ø©': 'ة',
            'Ø¡': 'ء',
            'Ù‰': 'ى',
            'ÙŽ': 'َ',
            'Ù': 'ُ',
            'Ù': 'ِ',
            'Ù‹': 'ً',
            'ÙŒ': 'ٌ',
            'Ù': 'ٍ',
            'Ù': 'ّ',
            'Ù': 'ْ',
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

  void _verifyRecitationAndProgress() {
    if (_transcriptions.isEmpty) return;

    String originalText = _currentAyah!['displayText'] ?? _currentAyah!['text'];
    String cleanOriginal = _prepareTextForComparison(originalText);
    String cleanTranscription = _prepareTextForComparison(_transcriptions.last);

    // Calculate match percentage
    int matchScore = _calculateMatchScore(cleanTranscription, cleanOriginal);
    int passThreshold = 70; // 70% accuracy required to pass

    bool isPassed = matchScore >= passThreshold;

    setState(() {
      _hasVerifiedCurrentAyah = true;

      if (isPassed && !_memorizedAyahIndices.contains(_currentAyahIndex)) {
        _memorizedAyahIndices.add(_currentAyahIndex);
        _newlyMemorizedAyahs++; // Increment newly memorized ayahs count
        
        // Update user stats immediately when an ayah is memorized
        _updateUserStats();
      }

      // Always show text after recitation for review
      _isTextVisible = true;

      // Show success message based on result
      _recordingStatus = isPassed
          ? 'Great ($matchScore% match)'
          : 'Try again ($matchScore% match)';
    });

    // Automatically move to next ayah if recitation is correct
    // if (isPassed) {
    //   // Add a small delay to show the success message before moving
    //   Future.delayed(const Duration(seconds: 2), () {
    //     _moveToNextAyah();
    //   });
    // }
  }

  void _moveToNextAyah() {
    if (_currentAyahIndex < ayahs.length - 1) {
      setState(() {
        _currentAyahIndex++;
        _currentAyah = ayahs[_currentAyahIndex];
        _transcriptions = []; // Clear previous transcriptions
        _hasVerifiedCurrentAyah = false;
        _isTextVisible = true; // Show text for the new ayah
        _recordingStatus = 'Tap to start recording';
      });
    } else {
      // Reached end of surah - mark as completed
      _didCompleteSurah = true;
      _updateUserStats(); // Final stats update for surah completion
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text(
              'You have completed memorization of this surah. MashaAllah!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _stopPracticing();
              },
              child: const Text('Return to Surah View'),
            ),
          ],
        ),
      );
    }
  }

  void _moveToPreviousAyah() {
    if (_currentAyahIndex > 0) {
      setState(() {
        _currentAyahIndex--;
        _currentAyah = ayahs[_currentAyahIndex];
        _transcriptions = []; // Clear previous transcriptions
        _hasVerifiedCurrentAyah = false;
        _isTextVisible = true; // Show text for the new ayah
        _recordingStatus = 'Tap to start recording';
      });
    }
  }

  void _stopPracticing() {
    setState(() {
      _currentAyah = null;
      _isPracticingAyah = false;
      _isRecording = false;
      _isPlaying = false;
    });
  }

  Future<void> _playRecording(String path) async {
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (!await file.exists()) {
          setState(() {
            _recordingStatus = 'Recording file not found';
          });
          return;
        }

        await _audioPlayer.setFilePath(path);
        await _audioPlayer.play();

        setState(() {
          _isPlaying = true;
          _recordingStatus = 'Playing recitation...';
        });

        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _recordingStatus = 'Ready to recite';
            });
          }
        }, onError: (e) {
          setState(() {
            _isPlaying = false;
            _recordingStatus = 'Error playing: ${e.toString()}';
          });
        });
      } catch (e) {
        setState(() {
          _recordingStatus = 'Error playing: ${e.toString()}';
          _isPlaying = false;
        });
      }
    } else {
      setState(() {
        _recordingStatus = 'No recitation to play';
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _recordingStatus = 'Ready to recite';
    });
  }

  String _prepareTextForComparison(String text) {
    // Instead of removing diacritics, only normalize alef forms
    // and perform other basic normalizations
    String result = text;

    // Normalize alef forms
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');

    // You might still want to normalize some whitespace
    result = result.trim();

    return result;
  }

  int _calculateMatchScore(String transcription, String original) {
    List<String> originalWords = original.split(' ');
    List<String> transcriptionWords = transcription.split(' ');

    int correctWords = 0;

    // More precise matching - compare each word
    for (int i = 0; i < transcriptionWords.length; i++) {
      if (i < originalWords.length &&
          transcriptionWords[i] == originalWords[i]) {
        correctWords++;
      }
    }

    int totalWords = math.max(originalWords.length, transcriptionWords.length);
    if (totalWords == 0) return 0;

    return (correctWords * 100 ~/ totalWords);
  }

  Widget _buildTranscriptionWithHighlightedErrors(
      String transcription, Map<String, dynamic> ayah) {
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
          text:
              i < transcriptionWords.length - 1 ? '$currentWord ' : currentWord,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Scheherazade',
            fontWeight: FontWeight.w500,
            // Change to white for correct words to match dark theme
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

  Future<void> _updateUserStats() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      
      if (userId == null) {
        print('Error: User ID is null, cannot update stats');
        return;
      }
      
      print('Updating user stats for user: $userId');
      print('Newly memorized ayahs in this session: $_newlyMemorizedAyahs');
      
      // Calculate session time
      final sessionTimeMinutes = _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inMinutes 
          : 0;
      
      // Get current stats first
      final statsResult = await _userStatsService.getUserStats(userId);
      
      if (statsResult['success']) {
        final currentStats = Map<String, dynamic>.from(statsResult['data']);
        print('Current stats from server: $currentStats');
        
        // Calculate new values - only add newly memorized ayahs from this session
        final currentMemorizedAyats = currentStats['memorizedAyats'] ?? 0;
        final newMemorizedAyatsTotal = currentMemorizedAyats + _newlyMemorizedAyahs;
        
        // Update memorized ayats if there are newly memorized ones
        if (_newlyMemorizedAyahs > 0) {
          print('Updating memorized ayats from $currentMemorizedAyats to $newMemorizedAyatsTotal');
          
          final ayatsResult = await _userStatsService.updateMemorizedAyats(userId, newMemorizedAyatsTotal);
          if (ayatsResult['success']) {
            print('Successfully updated memorized ayats');
            
            // Reset the newly memorized counter since we've updated the server
            _newlyMemorizedAyahs = 0;
          } else {
            print('Failed to update memorized ayats: ${ayatsResult['message']}');
          }
        }
        
        // Update memorized surahs if surah was completed
        if (_didCompleteSurah) {
          final currentMemorizedSurahs = currentStats['memorizedSurahs'] ?? 0;
          final newMemorizedSurahsTotal = currentMemorizedSurahs + 1;
          
          print('Updating memorized surahs from $currentMemorizedSurahs to $newMemorizedSurahsTotal');
          
          final surahsResult = await _userStatsService.updateMemorizedSurahs(userId, newMemorizedSurahsTotal);
          if (surahsResult['success']) {
            print('Successfully updated memorized surahs');
            _didCompleteSurah = false; // Reset flag
          } else {
            print('Failed to update memorized surahs: ${surahsResult['message']}');
          }
        }
        
        // Add time spent if session time > 0
        if (sessionTimeMinutes > 0) {
          print('Adding $sessionTimeMinutes minutes to time spent');
          
          final timeResult = await _userStatsService.addTimeSpent(userId, sessionTimeMinutes);
          if (timeResult['success']) {
            print('Successfully added time spent');
            // Reset session start time
            _sessionStartTime = DateTime.now();
          } else {
            print('Failed to add time spent: ${timeResult['message']}');
          }
        }
        
        // Update weekly progress for today - only if we have newly memorized ayahs
        final now = DateTime.now();
        final dayIndex = now.weekday - 1; // Monday = 0, Sunday = 6
        
        if (_memorizedAyahIndices.isNotEmpty) {
          print('Updating weekly progress for day $dayIndex');
          
          final currentWeeklyProgress = List<int>.from(currentStats['weeklyProgress'] ?? [0, 0, 0, 0, 0, 0, 0]);
          final todaysProgress = currentWeeklyProgress[dayIndex] + 1; // Add 1 for this ayah
          
          final weeklyResult = await _userStatsService.updateWeeklyProgress(
            userId, 
            dayIndex, 
            todaysProgress
          );
          if (!weeklyResult['success']) {
            print('Failed to update weekly progress: ${weeklyResult['message']}');
          }
        }
        
        // Update surah progress if applicable
        if (surahNumber != null) {
          final progressPercentage = (_memorizedAyahIndices.length / ayahs.length * 100).round();
          print('Updating surah $surahNumber progress to $progressPercentage%');
          
          final progressResult = await _userStatsService.updateSurahProgress(
            userId, 
            surahNumber!, 
            progressPercentage
          );
          if (!progressResult['success']) {
            print('Failed to update surah progress: ${progressResult['message']}');
          }
        }
        
        // Get updated stats and refresh UserProvider
        final updatedStatsResult = await _userStatsService.getUserStats(userId);
        if (updatedStatsResult['success']) {
          await userProvider.updateUserStats(updatedStatsResult['data']);
          print('Successfully updated all user stats!');
          
          // Force a rebuild
          if (mounted) {
            setState(() {
              // Just triggering a rebuild
            });
          }
        }
      } else {
        print('Failed to get current stats: ${statsResult['message']}');
      }
    } catch (e) {
      print('Error updating stats: $e');
      print('Stack trace: ${StackTrace.current}');
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : _buildSurahContent(),
    );
  }

  Widget _buildPracticePage() {
    if (_currentAyah == null)
      return const Center(child: Text('No ayah selected'));

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Text(
                    'Ayah ${_currentAyahIndex + 1} of ${ayahs.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ayahs.isEmpty
                            ? 0
                            : (_currentAyahIndex + 1) / ayahs.length,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_memorizedAyahIndices.length} memorized',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Current ayah (hidden during recording)
            if (_isTextVisible)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_currentAyah!['ayahNumber']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Current Ayah to Memorize',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _currentAyah!['displayText'] ?? _currentAyah!['text'],
                        style: const TextStyle(
                          fontSize: 28,
                          fontFamily: 'Scheherazade',
                          height: 2.0,
                          color: Colors.black,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Recitation status
            Text(
              _recordingStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // Recording controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Record button
                ElevatedButton(
                  onPressed: _isPlaying
                      ? null
                      : (_isRecording
                          ? () => _stopRecording(_currentAyah!)
                          : () => _startRecording(_currentAyah!)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isRecording ? Colors.red : const Color(0xFF05668D),
                    foregroundColor: Colors.white,
                    // Reduce padding to make button smaller
                    padding: const EdgeInsets.all(12),
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    // Reduce icon size
                    size: 28,
                  ),
                ),

                const SizedBox(width: 20),

                // Play button
                ElevatedButton(
                  onPressed: (_currentAyah != null &&
                          _currentAyah!['recordingPath'] != null &&
                          _currentAyah!['recordingPath']
                              .toString()
                              .isNotEmpty &&
                          !_isRecording)
                      ? (_isPlaying
                          ? _stopPlayback
                          : () =>
                              _playRecording(_currentAyah!['recordingPath']))
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isPlaying ? Colors.orange : const Color(0xFF028090),
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

            // API processing status
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _apiResult ?? "Processing recitation...",
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahContent() {
    if (ayahs.isEmpty) {
      return Center(child: Text('No ayahs to display'));
    }

    // Get current ayah
    final currentAyah = ayahs[_currentAyahIndex];

    // Get previous ayah if available
    final previousAyah =
        _currentAyahIndex > 0 ? ayahs[_currentAyahIndex - 1] : null;

    // Get next ayah if available
    final nextAyah = _currentAyahIndex < ayahs.length - 1
        ? ayahs[_currentAyahIndex + 1]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            const Color(0xFF121212), // Very dark gray
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
                Text(
                  'Memorized: ${_memorizedAyahIndices.length}/${ayahs.length} Ayahs',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ayahs.isEmpty
                        ? 0
                        : _memorizedAyahIndices.length / ayahs.length,
                    backgroundColor: Colors.grey.shade800,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Add dropdown for direct navigation to any verse
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Text(
                  'Go to Ayah: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF555555)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _currentAyahIndex,
                        dropdownColor: const Color(0xFF333333),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white70),
                        style: const TextStyle(color: Colors.white),
                        items: List.generate(ayahs.length, (index) {
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              'Ayah ${ayahs[index]['ayahNumber']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }),
                        onChanged: (int? newIndex) {
                          if (newIndex != null) {
                            setState(() {
                              _currentAyahIndex = newIndex;
                              _currentAyah = ayahs[newIndex];
                              _isPracticingCurrentAyah = false;
                              _transcriptions = [];
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Ayah cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Previous Ayah (if available)
                  if (previousAyah != null)
                    _buildAyahCard(previousAyah,
                        isCurrent: false,
                        isMemorized: _memorizedAyahIndices
                            .contains(previousAyah['ayahNumber']),
                        label: 'Previous Ayah'),

                  const SizedBox(height: 16),

                  // Current Ayah
                  _buildAyahCard(currentAyah,
                      isCurrent: true,
                      isMemorized: _memorizedAyahIndices
                          .contains(currentAyah['ayahNumber']),
                      label: 'Current Ayah'),

                  const SizedBox(height: 16),

                  // Next Ayah (if available)
                  if (nextAyah != null)
                    _buildAyahCard(nextAyah,
                        isCurrent: false,
                        isMemorized: _memorizedAyahIndices
                            .contains(nextAyah['ayahNumber']),
                        label: 'Next Ayah'),
                ],
              ),
            ),
          ),

          // Add this to the bottom of your _buildSurahContent method, just above the navigation controls
          // Only show when user has memorized at least 2 ayahs
          if (_memorizedAyahIndices.length >= 2)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(
                  top: BorderSide(color: const Color(0xFF333333), width: 1),
                  bottom: BorderSide(color: const Color(0xFF333333), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Find the maximum memorized ayah index
                      int maxMemorizedIndex = _memorizedAyahIndices.isNotEmpty
                          ? _memorizedAyahIndices.reduce(math.max)
                          : 0;

                      // Navigate to revision page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RevisionPage(
                            ayahs: ayahs,
                            memorizedIndices: _memorizedAyahIndices,
                            defaultStartIndex: 0,
                            defaultEndIndex: maxMemorizedIndex,
                            surahName: surahName ?? '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.repeat),
                    label: const Text('Revise Memorized Ayahs'),
                  ),
                ],
              ),
            ),

          // Navigation controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: _currentAyahIndex > 0 ? _moveToPreviousAyah : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),

                // Next button
                ElevatedButton.icon(
                  onPressed: _currentAyahIndex < ayahs.length - 1
                      ? _moveToNextAyah
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard(Map<String, dynamic> ayah,
      {required bool isCurrent,
      required bool isMemorized,
      required String label}) {
    final bool isPracticing = isCurrent && _isPracticingCurrentAyah;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isCurrent ? 4 : 1,
      // Change card background to white instead of dark
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
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
                    color: isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
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
                // Also update the label text color for better visibility on white background
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    // Change to a darker color that works on white background
                    color: isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (isMemorized) Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),

            // Show text only if not practicing or if text should be visible
            if (!isPracticing || _isTextVisible)
              Text(
                ayah['displayText'] ?? ayah['text'],
                style: TextStyle(
                  fontSize: isCurrent ? 26 : 20,
                  fontFamily: 'Scheherazade',
                  height: 1.8,
                  // Change text color for better contrast on dark background
                  color: Colors.black,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),

            // Practice section shown directly in the card when practicing
            if (isPracticing) ...[
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  ElevatedButton(
                    onPressed: _isPlaying
                        ? null
                        : (_isRecording
                            ? () => _stopRecording(ayah)
                            : () => _startRecording(ayah)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isRecording ? Colors.red : const Color(0xFF05668D),
                      foregroundColor: Colors.white,
                      // Reduce padding to make button smaller
                      padding: const EdgeInsets.all(12),
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      // Reduce icon size
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Play button (if recording exists)
                  // Update the play button size in the row of controls
                  if (ayah['hasRecording'] == true)
                    ElevatedButton(
                      onPressed: !_isRecording
                          ? (_isPlaying
                              ? _stopPlayback
                              : () => _playRecording(ayah['recordingPath']))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying
                            ? Colors.orange
                            : const Color(0xFF028090),
                        foregroundColor: Colors.white,
                        // Make padding same as record button
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.stop : Icons.play_arrow,
                        // Make icon size same as record button
                        size: 28,
                      ),
                    ),
                ],
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
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                    // Light background for container
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your recitation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTranscriptionWithHighlightedErrors(
                          _transcriptions.last, ayah),
                    ],
                  ),
                ),
              ],
            ],

            // Practice/Review Button - Only show when not already practicing
            if ((isCurrent || isMemorized) && !isPracticing)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentAyah = ayah;
                          _isPracticingCurrentAyah = true;
                          _isTextVisible = true;
                          _transcriptions = [];
                          // Start recording immediately
                          _startRecording(ayah);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05668D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.mic, size: 24),
                    ),
                    if (isMemorized)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentAyah = ayah;
                              _currentAyahIndex = ayahs.indexWhere(
                                  (a) => a['ayahNumber'] == ayah['ayahNumber']);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.replay, size: 24),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}