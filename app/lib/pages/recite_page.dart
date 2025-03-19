// Add these imports at the top with your other imports
import 'package:http/http.dart' as http;
import 'package:queue/queue.dart';
import 'dart:convert';
import 'dart:math'; // Add this import for min function
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class RecitePage extends StatefulWidget {
  final String? selectedSurah;
  final String? selectedReciter;
  final Map<String, dynamic>? surahInfo;
  
  const RecitePage({
    super.key, 
    this.selectedSurah,
    this.selectedReciter,
    this.surahInfo,
  });

  @override
  State<RecitePage> createState() => _RecitePageState();
}

class _RecitePageState extends State<RecitePage> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _reciterAudioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isReciterPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start reciting';
  
  // API variables for transcription
  static const String _apiToken = "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";
  static const String _apiUrl = "https://api-inference.huggingface.co/models/tarteel-ai/whisper-base-ar-quran";
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
  
  @override
  void initState() {
    super.initState();
    _loadSurahContent();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _reciterAudioPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _loadSurahContent() async {
  if (widget.surahInfo == null && widget.selectedSurah == null) {
    setState(() {
      isLoading = false;
    });
    return;
  }

  try {
    // Load the Quran text from the JSON file
    final String jsonData = await rootBundle.loadString('assets/data/quran.json');
    final Map<String, dynamic> quranData = json.decode(jsonData);
    
    // Get surah number - either from surahInfo or from selectedSurah
    int? surahNumber;
    if (widget.surahInfo != null) {
      surahNumber = widget.surahInfo!['surahNumber'];
    } else if (widget.selectedSurah != null) {
      // Map surah name to number - simplified example
      final Map<String, int> surahMap = {
        'Al-Fatihah': 1, 'Al-Baqarah': 2, 'Ali-Imran': 3, 'An-Nisa': 4,
        'Al-Maidah': 5, 'Al-Anam': 6, 'Al-Araf': 7, 'Al-Anfal': 8
      };
      surahNumber = surahMap[widget.selectedSurah];
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
        'displayText': ayahData['displayText'], // Text with diacritics for display
        'hasRecording': false,
        'recordingPath': null,
      });
    });
    
    // Sort ayahs by ayah number
    parsedAyahs.sort((a, b) => a['ayahNumber'].compareTo(b['ayahNumber']));
    
    setState(() {
      ayahs = parsedAyahs;
      isLoading = false;
    });
    
    debugPrint('Loaded ${ayahs.length} ayahs for surah $surahNumber');
    
  } catch (e) {
    setState(() {
      isLoading = false;
      errorMessage = 'Error loading surah content: $e';
    });
    debugPrint('Error loading surah content: $e');
    debugPrintStack();
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

      final directory = await getTemporaryDirectory();
      String fileName = 'surah_${ayah['surahNumber']}_ayah_${ayah['ayahNumber']}_${DateTime.now().millisecondsSinceEpoch}.wav';
      
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
      });
    }
  }

  Future<void> _stopRecording(Map<String, dynamic> ayah) async {
    try {
      final path = await _audioRecorder.stop();
      
      if (path != null) {
        // Update the ayah with recording information
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
          
          // Also update current ayah if we're in practice mode
          if (_currentAyah != null) {
            _currentAyah!['hasRecording'] = true;
            _currentAyah!['recordingPath'] = path;
          }
        });
        
        // Debug print to verify path
        debugPrint('Recording saved at: $path');
        
        // Enqueue API request for transcription
        _enqueueApiRequest(path);
      } else {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Failed to save recitation';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Error when stopping: ${e.toString()}';
      });
    }
  }

  Future<void> _playRecording(String path) async {
    if (path != null && path.isNotEmpty) {
      try {
        // Check if file exists
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
        });
      } catch (e) {
        setState(() {
          _recordingStatus = 'Error playing: ${e.toString()}';
          _isPlaying = false;
        });
        debugPrint('Playback error: ${e.toString()}');
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
  
  void _startPracticing(Map<String, dynamic> ayah) {
    setState(() {
      // Create a deep copy of the ayah and ensure recordingPath is properly set
      _currentAyah = Map<String, dynamic>.from(ayah);
      _isPracticingAyah = true;
      _transcriptions = []; // Clear previous transcriptions for new practice session
    });
  }
  
  void _stopPracticing() {
    setState(() {
      _currentAyah = null;
      _isPracticingAyah = false;
      _isRecording = false;
      _isPlaying = false;
    });
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

  // Update your _playReciterAudio method to try MP3 files if WAV files don't work
Future<void> _playReciterAudio(int surahNumber, int ayahNumber) async {
  try {
    // Special handling for the problematic files
    if (surahNumber == 1 && (ayahNumber == 1 || ayahNumber == 2)) {
      return await _playProblemAudio(surahNumber, ayahNumber);
    }
    
    // Regular handling for other files
    if (_isPlaying) await _audioPlayer.stop();
    if (_isReciterPlaying) await _reciterAudioPlayer.stop();
    
    // Format the filename with both WAV and MP3 options
    final formattedSurah = surahNumber.toString().padLeft(3, '0');
    final formattedAyah = ayahNumber.toString().padLeft(3, '0');
    
    // Try multiple file extensions
    final fileNameWav = '$formattedSurah$formattedAyah.wav';
    final fileNameMp3 = '$formattedSurah$formattedAyah.mp3';
    
    // Determine reciter folder
    String reciterFolder;
    if (widget.selectedReciter == 'Sheikh Abdul Basit Abdul Samad') {
      reciterFolder = 'abdul_basit';
    } else if (widget.selectedReciter == 'Sheikh Abdul Rahman Al-Sudais') {
      reciterFolder = 'sudais';
    } else {
      reciterFolder = 'abdul_basit'; // Default
    }
    
    // Add the correct subfolder
    String subfolder = '';
    if (surahNumber == 1) {
      subfolder = 'fatihah/';
    } else if (surahNumber == 2) {
      subfolder = 'baqarah/';
    }
    
    setState(() {
      _recordingStatus = 'Playing ${widget.selectedReciter ?? "reciter"}\'s recitation...';
      _isReciterPlaying = true;
    });
    
    // Try WAV first, then MP3 if that fails
    bool success = false;
    
    try {
      final wavPath = 'assets/audio/reciters/$reciterFolder/$subfolder$fileNameWav';
      print('Trying WAV file: $wavPath');
      await _reciterAudioPlayer.setAsset(wavPath);
      await _reciterAudioPlayer.play();
      success = true;
    } catch (wavError) {
      print('WAV file failed: $wavError');
      
      try {
        final mp3Path = 'assets/audio/reciters/$reciterFolder/$subfolder$fileNameMp3';
        print('Trying MP3 file: $mp3Path');
        await _reciterAudioPlayer.setAsset(mp3Path);
        await _reciterAudioPlayer.play();
        success = true;
      } catch (mp3Error) {
        print('MP3 file failed: $mp3Error');
        throw mp3Error;
      }
    }
    
    // Update status when playback completes
    _reciterAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isReciterPlaying = false;
          _recordingStatus = 'Ready to recite';
        });
      }
    });
  } catch (e) {
    print('Error playing recitation: $e');
    setState(() {
      _isReciterPlaying = false;
      _recordingStatus = 'Error playing recitation: ${e.toString()}';
    });
  }
}

Future<void> _playAbdulBasitRecitation(int surahNumber, int ayahNumber) async {
  try {
    // First stop any current playback
    if (_isPlaying) await _audioPlayer.stop();
    if (_isReciterPlaying) await _reciterAudioPlayer.stop();
    
    // Format the filename: surah 1, ayah 1 => 001001.wav
    final formattedSurah = surahNumber.toString().padLeft(3, '0');
    final formattedAyah = ayahNumber.toString().padLeft(3, '0');
    final fileName = '$formattedSurah$formattedAyah.wav';
    final assetPath = 'assets/audio/reciters/abdul_basit/fatihah/$fileName';
    
    print('Attempting to play audio from asset path: $assetPath');
    
    setState(() {
      _recordingStatus = 'Playing Abdul Basit\'s recitation...';
      _isReciterPlaying = true;
    });
    
    await _reciterAudioPlayer.setAsset(assetPath);
    await _reciterAudioPlayer.play();
    
    // Update status when playback completes
    _reciterAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isReciterPlaying = false;
          _recordingStatus = 'Ready to recite';
        });
      }
    });
  } catch (e) {
    print('Error playing recitation: $e');
    print('Stack trace: ${StackTrace.current}');
    setState(() {
      _isReciterPlaying = false;
      _recordingStatus = 'Error playing recitation: ${e.toString()}';
    });
  }
}

Future<void> _playProblemAudio(int surahNumber, int ayahNumber) async {
  try {
    // First stop any current playback
    if (_isPlaying) await _audioPlayer.stop();
    if (_isReciterPlaying) await _reciterAudioPlayer.stop();
    
    // Format the filename
    final formattedSurah = surahNumber.toString().padLeft(3, '0');
    final formattedAyah = ayahNumber.toString().padLeft(3, '0');
    final fileName = '$formattedSurah$formattedAyah.wav';
    
    setState(() {
      _recordingStatus = 'Processing audio...';
      _isReciterPlaying = true;
    });
    
    // Get the asset as a byte array and create a temporary file
    final assetPath = 'assets/audio/reciters/abdul_basit/fatihah/$fileName';
    print('Extracting problematic file: $assetPath');
    
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      
      // Load asset as bytes
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes, 
        data.lengthInBytes
      );
      
      // Write to temp file
      await tempFile.writeAsBytes(bytes);
      print('Wrote file to: ${tempFile.path}, size: ${bytes.length} bytes');
      
      // Try to play using the file path instead of the asset
      await _reciterAudioPlayer.setFilePath(tempFile.path);
      
      setState(() {
        _recordingStatus = 'Playing ${widget.selectedReciter ?? "reciter"}\'s recitation...';
      });
      
      await _reciterAudioPlayer.play();
      
      // Update status when playback completes
      _reciterAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isReciterPlaying = false;
            _recordingStatus = 'Ready to recite';
          });
        }
      });
    } catch (e) {
      print('Error with file extraction approach: $e');
      throw e;
    }
  } catch (e) {
    print('Error playing problematic audio: $e');
    setState(() {
      _isReciterPlaying = false;
      _recordingStatus = 'Error playing recitation: ${e.toString()}';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final bool isFromLehja = widget.selectedReciter != null;
    final String title = widget.surahInfo != null 
      ? '${widget.surahInfo!['surahName']}' 
      : (widget.selectedSurah != null ? widget.selectedSurah! : 'Recitation');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isFromLehja ? 'Lehja Practice - $title' : 'Recitation - $title'),
        backgroundColor: const Color(0xFF00A896), // Match Hifz page color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isPracticingAyah ? _buildPracticePage() : _buildSurahPage(),
    );
  }
  
  Widget _buildSurahPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (errorMessage.isNotEmpty) {
      return _buildErrorView();
    } else {
      return _buildSurahContent();
    }
  }
  
  Widget _buildPracticePage() {
    if (_currentAyah == null) return const Center(child: Text('No ayah selected'));
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            const Color(0xFF121212),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 80,
                color: const Color(0xFF00A896),
              ),
              const SizedBox(height: 20),
              Text(
                'Practice Ayah ${_currentAyah!['ayahNumber']}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Ayah text display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A896).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF00A896),
                    width: 2,
                  ),
                ),
                child: Text(
                  _currentAyah!['displayText'] ?? _currentAyah!['text'],
                  style: const TextStyle(
                    fontSize: 26,
                    fontFamily: 'Scheherazade',
                    height: 1.8,
                    color: Colors.black,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                _recordingStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  ElevatedButton(
                    onPressed: _isPlaying ? null : (_isRecording 
                      ? () => _stopRecording(_currentAyah!) 
                      : () => _startRecording(_currentAyah!)),
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
                  
                  // Play button
                  ElevatedButton(
                    onPressed: (_currentAyah != null && 
                                _currentAyah!['recordingPath'] != null && 
                                _currentAyah!['recordingPath'].toString().isNotEmpty && 
                                !_isRecording) 
                        ? (_isPlaying ? _stopPlayback : () => _playRecording(_currentAyah!['recordingPath']))
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.orange : const Color(0xFF028090),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 36,
                    ),
                  ),
                  
                  // Update in the _buildPracticePage method
                  if (_currentAyah != null && _currentAyah!['surahNumber'] == 1) ...[
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: !_isRecording && !_isReciterPlaying 
                          ? () => _playReciterAudio(_currentAyah!['surahNumber'], _currentAyah!['ayahNumber']) 
                          : (_isReciterPlaying ? () => _reciterAudioPlayer.stop() : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isReciterPlaying ? Colors.orange.shade800 : Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        _isReciterPlaying ? Icons.stop : Icons.headphones,
                        size: 36,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
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
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A896)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _apiResult ?? "Processing recitation...",
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Transcription Display
              if (_transcriptions.isNotEmpty) ...[
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00A896), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transcription:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF00A896),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var transcription in _transcriptions)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _buildTranscriptionWithHighlightedErrors(
                            transcription, 
                            _currentAyah!
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Note: Words in red indicate possible recitation mistakes',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
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
                    color: Colors.red.withOpacity(0.2),
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
              
              // Back to surah button
              ElevatedButton.icon(
                onPressed: _stopPracticing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Surah'),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            const Color(0xFF121212),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load surah content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(errorMessage, 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = '';
                  });
                  _loadSurahContent();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahContent() {
    if (ayahs.isEmpty) {
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.selectedReciter != null ? Icons.headphones : Icons.menu_book,
                  size: 80,
                  color: const Color(0xFF00A896),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.selectedReciter != null 
                    ? 'Practice with ${widget.selectedReciter}'
                    : 'Quran Recitation',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select a surah to begin practicing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          )
        ),
      );
    }

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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ayahs.length,
        itemBuilder: (context, index) {
          final ayah = ayahs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Match the card color with Hifz page
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          // Match primary color with Hifz page
                          color: Color(0xFF00A896),
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
                      const Spacer(),
                      // Add this button for Abdul Basit recitation
                      if (ayah['surahNumber'] == 1) // Show only for Surah Al-Fatiha
                        IconButton(
                          icon: Icon(
                            Icons.headphones,
                            color: Colors.amber.shade800,
                          ),
                          tooltip: 'Listen to ${widget.selectedReciter ?? "Abdul Basit"}\'s recitation',
                          onPressed: () => _playReciterAudio(ayah['surahNumber'], ayah['ayahNumber']),
                        ),
                      if (ayah['hasRecording']) 
                        Tooltip(
                          message: 'You have a recording for this ayah',
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.mic),
                        tooltip: 'Practice this ayah',
                        onPressed: () => _startPracticing(ayah),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy),
                        tooltip: 'Copy ayah text',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ayah['text']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ayah copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ayah['displayText'] ?? ayah['text'], // Use displayText if available, otherwise fallback to text
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Scheherazade',
                      height: 1.8,
                      color: Colors.black, // Added black color to make text more visible
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionWithHighlightedErrors(String transcription, Map<String, dynamic> ayah) {
    // Get the display text with diacritics for comparison
    String originalText = ayah['displayText'] ?? ayah['text'];
    
    // Clean up text for better comparison - remove some diacritics but keep essential ones
    String cleanOriginal = _prepareTextForComparison(originalText);
    String cleanTranscription = _prepareTextForComparison(transcription);
    
    List<String> originalWords = cleanOriginal.split(' ');
    List<String> transcriptionWords = cleanTranscription.split(' ');
    
    // Create list of TextSpans for rich text display
    List<TextSpan> textSpans = [];
    
    // Create a map of original words for quick matching
    Set<String> originalWordsSet = originalWords.toSet();
    
    for (int i = 0; i < transcriptionWords.length; i++) {
      String currentWord = transcriptionWords[i];
      bool isCorrect = _wordExistsInOriginal(currentWord, originalWordsSet);
      
      // Add word with appropriate color
      textSpans.add(
        TextSpan(
          text: i < transcriptionWords.length - 1 ? '$currentWord ' : currentWord,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isCorrect ? Colors.black : Colors.red,
            fontFamily: 'Scheherazade',
          ),
        ),
      );
    }
    
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(children: textSpans),
    );
  }

  // Helper method to prepare text for comparison - more sophisticated
  String _prepareTextForComparison(String text) {
    // Keep essential diacritics but remove less important ones
    final nonEssentialDiacritics = [
      '\u064B', // FATHATAN
      '\u064C', // DAMMATAN
      '\u064D', // KASRATAN
      '\u0652', // SUKUN
      '\u0670', // SUPERSCRIPT ALEF
      // You can customize this list
    ];
    
    String result = text;
    for (String diacritic in nonEssentialDiacritics) {
      result = result.replaceAll(diacritic, '');
    }
    
    // Remove tatweel (elongation character)
    result = result.replaceAll('\u0640', '');
    
    return result.trim();
  }

  // Improved word matching function
  bool _wordExistsInOriginal(String word, Set<String> originalWords) {
    // Direct match
    if (originalWords.contains(word)) return true;
    
    // Try comparing roots (simplified approach)
    for (String original in originalWords) {
      if (_compareArabicWordRoots(word, original)) {
        return true;
      }
    }
    
    return false;
  }

  // Simple root comparison (this is a basic version - could be more sophisticated)
  bool _compareArabicWordRoots(String word1, String word2) {
    // Remove all diacritics for root comparison
    String root1 = _removeDiacritics(word1);
    String root2 = _removeDiacritics(word2);
    
    // If words are short, they must match exactly
    if (root1.length <= 3 || root2.length <= 3) {
      return root1 == root2;
    }
    
    // For longer words, check if they share a common stem
    int minLength = min(root1.length, root2.length);
    int matchThreshold = (minLength * 0.7).ceil(); // 70% similarity
    
    int matchCount = 0;
    for (int i = 0; i < minLength; i++) {
      if (root1[i] == root2[i]) matchCount++;
    }
    
    return matchCount >= matchThreshold;
  }

  // This function completely removes all diacritics
  String _removeDiacritics(String text) {
    // All Arabic diacritics
    final diacritics = [
      '\u064B', '\u064C', '\u064D', '\u064E', '\u064F',
      '\u0650', '\u0651', '\u0652', '\u0653', '\u0654',
      '\u0655', '\u0656', '\u0657', '\u0658', '\u0659',
      '\u065A', '\u065B', '\u065C', '\u065D', '\u065E',
      '\u065F', '\u0670'
    ];
    
    String result = text;
    for (String diacritic in diacritics) {
      result = result.replaceAll(diacritic, '');
    }
    
    return result.trim();
  }
}