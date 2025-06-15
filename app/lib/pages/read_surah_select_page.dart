import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class ReadSurahSelectPage extends StatefulWidget {
  const ReadSurahSelectPage({super.key});

  @override
  State<ReadSurahSelectPage> createState() => _ReadSurahSelectPageState();
}

// First, define the SurahSearchDelegate class that was missing
class SurahSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> surahs;
  final Function(Map<String, dynamic>) onSelect;

  SurahSearchDelegate(this.surahs, this.onSelect);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF00A896).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: const Center(
          child: Text('Type to search for a surah'),
        ),
      );
    }

    final results = surahs.where((surah) {
      return surah['name'].toLowerCase().contains(query.toLowerCase()) ||
          surah['number'].toString() == query;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00A896).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final surah = results[index];
          return ListTile(
            onTap: () {
              // Create properly formatted surahInfo object with integer surahNumber
              final surahInfo = {
                'surahNumber': surah['number'] as int, // Explicitly cast to int
                'surahName': surah['name'],
                'arabicName': surah['arabicName'],
                'ayahCount': surah['ayahs'],
              };
              onSelect(surahInfo);
              close(context, surahInfo);
            },
            leading: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFF00A896).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${surah['number']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A896),
                  ),
                ),
              ),
            ),
            title: Text(
              surah['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text('${surah['ayahs']} ayahs'),
            trailing: Text(
              surah['arabicName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Scheherazade',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadSurahSelectPageState extends State<ReadSurahSelectPage> {
  // Voice search variables
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordingPath;
  String _voiceSearchStatus = 'Tap microphone to search by voice';

  // API variables for transcription
  static const String _apiToken = "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";
  static const String _apiUrl =
      "https://vb1pti1yhtwgtlth.us-east-1.aws.endpoints.huggingface.cloud";
  bool _isProcessing = false;
  String? _apiResult;
  List<String> _transcriptions = [];

  // All Quran data for search
  Map<String, dynamic> allQuranData = {};
  
  // Search results
  List<Map<String, dynamic>> searchResults = [];
  bool _showSearchResults = false;
  // List of surahs with their names and number of ayahs
  final List<Map<String, dynamic>> _surahs = [
    {'number': 1, 'name': 'Al-Fatiha', 'arabicName': 'الفاتحة', 'ayahs': 7},
    {'number': 2, 'name': 'Al-Baqara', 'arabicName': 'البقرة', 'ayahs': 286},
    {'number': 3, 'name': 'Aali Imran', 'arabicName': 'آل عمران', 'ayahs': 200},
    {'number': 4, 'name': 'An-Nisa', 'arabicName': 'النساء', 'ayahs': 176},
    {'number': 5, 'name': 'Al-Ma\'idah', 'arabicName': 'المائدة', 'ayahs': 120},
    {'number': 6, 'name': 'Al-An\'am', 'arabicName': 'الأنعام', 'ayahs': 165},
    {'number': 7, 'name': 'Al-A\'raf', 'arabicName': 'الأعراف', 'ayahs': 206},
    {'number': 8, 'name': 'Al-Anfal', 'arabicName': 'الأنفال', 'ayahs': 75},
    {'number': 9, 'name': 'At-Tawbah', 'arabicName': 'التوبة', 'ayahs': 129},
    {'number': 10, 'name': 'Yunus', 'arabicName': 'يونس', 'ayahs': 109},
    {'number': 11, 'name': 'Hud', 'arabicName': 'هود', 'ayahs': 123},
    {'number': 12, 'name': 'Yusuf', 'arabicName': 'يوسف', 'ayahs': 111},
    {'number': 13, 'name': 'Ar-Ra\'d', 'arabicName': 'الرعد', 'ayahs': 43},
    {'number': 14, 'name': 'Ibrahim', 'arabicName': 'إبراهيم', 'ayahs': 52},
    {'number': 15, 'name': 'Al-Hijr', 'arabicName': 'الحجر', 'ayahs': 99},
    {'number': 16, 'name': 'An-Nahl', 'arabicName': 'النحل', 'ayahs': 128},
    {'number': 17, 'name': 'Al-Isra', 'arabicName': 'الإسراء', 'ayahs': 111},
    {'number': 18, 'name': 'Al-Kahf', 'arabicName': 'الكهف', 'ayahs': 110},
    {'number': 19, 'name': 'Maryam', 'arabicName': 'مريم', 'ayahs': 98},
    {'number': 20, 'name': 'Ta-Ha', 'arabicName': 'طه', 'ayahs': 135},
    {'number': 21, 'name': 'Al-Anbiya', 'arabicName': 'الأنبياء', 'ayahs': 112},
    {'number': 22, 'name': 'Al-Hajj', 'arabicName': 'الحج', 'ayahs': 78},
    {'number': 23, 'name': 'Al-Mu\'minun', 'arabicName': 'المؤمنون', 'ayahs': 118},
    {'number': 24, 'name': 'An-Nur', 'arabicName': 'النور', 'ayahs': 64},
    {'number': 25, 'name': 'Al-Furqan', 'arabicName': 'الفرقان', 'ayahs': 77},
    {'number': 26, 'name': 'Ash-Shu\'ara', 'arabicName': 'الشعراء', 'ayahs': 227},
    {'number': 27, 'name': 'An-Naml', 'arabicName': 'النمل', 'ayahs': 93},
    {'number': 28, 'name': 'Al-Qasas', 'arabicName': 'القصص', 'ayahs': 88},
    {'number': 29, 'name': 'Al-Ankabut', 'arabicName': 'العنكبوت', 'ayahs': 69},
    {'number': 30, 'name': 'Ar-Rum', 'arabicName': 'الروم', 'ayahs': 60},
    {'number': 31, 'name': 'Luqman', 'arabicName': 'لقمان', 'ayahs': 34},
    {'number': 32, 'name': 'As-Sajdah', 'arabicName': 'السجدة', 'ayahs': 30},
    {'number': 33, 'name': 'Al-Ahzab', 'arabicName': 'الأحزاب', 'ayahs': 73},
    {'number': 34, 'name': 'Saba', 'arabicName': 'سبأ', 'ayahs': 54},
    {'number': 35, 'name': 'Fatir', 'arabicName': 'فاطر', 'ayahs': 45},
    {'number': 36, 'name': 'Ya-Sin', 'arabicName': 'يس', 'ayahs': 83},
    {'number': 37, 'name': 'As-Saffat', 'arabicName': 'الصافات', 'ayahs': 182},
    {'number': 38, 'name': 'Sad', 'arabicName': 'ص', 'ayahs': 88},
    {'number': 39, 'name': 'Az-Zumar', 'arabicName': 'الزمر', 'ayahs': 75},
    {'number': 40, 'name': 'Ghafir', 'arabicName': 'غافر', 'ayahs': 85},
    {'number': 41, 'name': 'Fussilat', 'arabicName': 'فصلت', 'ayahs': 54},
    {'number': 42, 'name': 'Ash-Shura', 'arabicName': 'الشورى', 'ayahs': 53},
    {'number': 43, 'name': 'Az-Zukhruf', 'arabicName': 'الزخرف', 'ayahs': 89},
    {'number': 44, 'name': 'Ad-Dukhan', 'arabicName': 'الدخان', 'ayahs': 59},
    {'number': 45, 'name': 'Al-Jathiyah', 'arabicName': 'الجاثية', 'ayahs': 37},
    {'number': 46, 'name': 'Al-Ahqaf', 'arabicName': 'الأحقاف', 'ayahs': 35},
    {'number': 47, 'name': 'Muhammad', 'arabicName': 'محمد', 'ayahs': 38},
    {'number': 48, 'name': 'Al-Fath', 'arabicName': 'الفتح', 'ayahs': 29},
    {'number': 49, 'name': 'Al-Hujurat', 'arabicName': 'الحجرات', 'ayahs': 18},
    {'number': 50, 'name': 'Qaf', 'arabicName': 'ق', 'ayahs': 45},
    {'number': 51, 'name': 'Adh-Dhariyat', 'arabicName': 'الذاريات', 'ayahs': 60},
    {'number': 52, 'name': 'At-Tur', 'arabicName': 'الطور', 'ayahs': 49},
    {'number': 53, 'name': 'An-Najm', 'arabicName': 'النجم', 'ayahs': 62},
    {'number': 54, 'name': 'Al-Qamar', 'arabicName': 'القمر', 'ayahs': 55},
    {'number': 55, 'name': 'Ar-Rahman', 'arabicName': 'الرحمن', 'ayahs': 78},
    {'number': 56, 'name': 'Al-Waqi\'ah', 'arabicName': 'الواقعة', 'ayahs': 96},
    {'number': 57, 'name': 'Al-Hadid', 'arabicName': 'الحديد', 'ayahs': 29},
    {'number': 58, 'name': 'Al-Mujadilah', 'arabicName': 'المجادلة', 'ayahs': 22},
    {'number': 59, 'name': 'Al-Hashr', 'arabicName': 'الحشر', 'ayahs': 24},
    {'number': 60, 'name': 'Al-Mumtahanah', 'arabicName': 'الممتحنة', 'ayahs': 13},
    {'number': 61, 'name': 'As-Saff', 'arabicName': 'الصف', 'ayahs': 14},
    {'number': 62, 'name': 'Al-Jumu\'ah', 'arabicName': 'الجمعة', 'ayahs': 11},
    {'number': 63, 'name': 'Al-Munafiqun', 'arabicName': 'المنافقون', 'ayahs': 11},
    {'number': 64, 'name': 'At-Taghabun', 'arabicName': 'التغابن', 'ayahs': 18},
    {'number': 65, 'name': 'At-Talaq', 'arabicName': 'الطلاق', 'ayahs': 12},
    {'number': 66, 'name': 'At-Tahrim', 'arabicName': 'التحريم', 'ayahs': 12},
    {'number': 67, 'name': 'Al-Mulk', 'arabicName': 'الملك', 'ayahs': 30},
    {'number': 68, 'name': 'Al-Qalam', 'arabicName': 'القلم', 'ayahs': 52},
    {'number': 69, 'name': 'Al-Haqqah', 'arabicName': 'الحاقة', 'ayahs': 52},
    {'number': 70, 'name': 'Al-Ma\'arij', 'arabicName': 'المعارج', 'ayahs': 44},
    {'number': 71, 'name': 'Nuh', 'arabicName': 'نوح', 'ayahs': 28},
    {'number': 72, 'name': 'Al-Jinn', 'arabicName': 'الجن', 'ayahs': 28},
    {'number': 73, 'name': 'Al-Muzzammil', 'arabicName': 'المزمل', 'ayahs': 20},
    {'number': 74, 'name': 'Al-Muddaththir', 'arabicName': 'المدثر', 'ayahs': 56},
    {'number': 75, 'name': 'Al-Qiyamah', 'arabicName': 'القيامة', 'ayahs': 40},
    {'number': 76, 'name': 'Al-Insan', 'arabicName': 'الإنسان', 'ayahs': 31},
    {'number': 77, 'name': 'Al-Mursalat', 'arabicName': 'المرسلات', 'ayahs': 50},
    {'number': 78, 'name': 'An-Naba', 'arabicName': 'النبأ', 'ayahs': 40},
    {'number': 79, 'name': 'An-Nazi\'at', 'arabicName': 'النازعات', 'ayahs': 46},
    {'number': 80, 'name': 'Abasa', 'arabicName': 'عبس', 'ayahs': 42},
    {'number': 81, 'name': 'At-Takwir', 'arabicName': 'التكوير', 'ayahs': 29},
    {'number': 82, 'name': 'Al-Infitar', 'arabicName': 'الانفطار', 'ayahs': 19},
    {'number': 83, 'name': 'Al-Mutaffifin', 'arabicName': 'المطففين', 'ayahs': 36},
    {'number': 84, 'name': 'Al-Inshiqaq', 'arabicName': 'الانشقاق', 'ayahs': 25},
    {'number': 85, 'name': 'Al-Buruj', 'arabicName': 'البروج', 'ayahs': 22},
    {'number': 86, 'name': 'At-Tariq', 'arabicName': 'الطارق', 'ayahs': 17},
    {'number': 87, 'name': 'Al-A\'la', 'arabicName': 'الأعلى', 'ayahs': 19},
    {'number': 88, 'name': 'Al-Ghashiyah', 'arabicName': 'الغاشية', 'ayahs': 26},
    {'number': 89, 'name': 'Al-Fajr', 'arabicName': 'الفجر', 'ayahs': 30},
    {'number': 90, 'name': 'Al-Balad', 'arabicName': 'البلد', 'ayahs': 20},
    {'number': 91, 'name': 'Ash-Shams', 'arabicName': 'الشمس', 'ayahs': 15},
    {'number': 92, 'name': 'Al-Layl', 'arabicName': 'الليل', 'ayahs': 21},
    {'number': 93, 'name': 'Ad-Duha', 'arabicName': 'الضحى', 'ayahs': 11},
    {'number': 94, 'name': 'Ash-Sharh', 'arabicName': 'الشرح', 'ayahs': 8},
    {'number': 95, 'name': 'At-Tin', 'arabicName': 'التين', 'ayahs': 8},
    {'number': 96, 'name': 'Al-Alaq', 'arabicName': 'العلق', 'ayahs': 19},
    {'number': 97, 'name': 'Al-Qadr', 'arabicName': 'القدر', 'ayahs': 5},
    {'number': 98, 'name': 'Al-Bayyinah', 'arabicName': 'البينة', 'ayahs': 8},
    {'number': 99, 'name': 'Az-Zalzalah', 'arabicName': 'الزلزلة', 'ayahs': 8},
    {'number': 100, 'name': 'Al-Adiyat', 'arabicName': 'العاديات', 'ayahs': 11},
    {'number': 101, 'name': 'Al-Qari\'ah', 'arabicName': 'القارعة', 'ayahs': 11},
    {'number': 102, 'name': 'At-Takathur', 'arabicName': 'التكاثر', 'ayahs': 8},
    {'number': 103, 'name': 'Al-Asr', 'arabicName': 'العصر', 'ayahs': 3},
    {'number': 104, 'name': 'Al-Humazah', 'arabicName': 'الهمزة', 'ayahs': 9},
    {'number': 105, 'name': 'Al-Fil', 'arabicName': 'الفيل', 'ayahs': 5},
    {'number': 106, 'name': 'Quraysh', 'arabicName': 'قريش', 'ayahs': 4},
    {'number': 107, 'name': 'Al-Ma\'un', 'arabicName': 'الماعون', 'ayahs': 7},
    {'number': 108, 'name': 'Al-Kawthar', 'arabicName': 'الكوثر', 'ayahs': 3},
    {'number': 109, 'name': 'Al-Kafirun', 'arabicName': 'الكافرون', 'ayahs': 6},
    {'number': 110, 'name': 'An-Nasr', 'arabicName': 'النصر', 'ayahs': 3},
    {'number': 111, 'name': 'Al-Masad', 'arabicName': 'المسد', 'ayahs': 5},
    {'number': 112, 'name': 'Al-Ikhlas', 'arabicName': 'الإخلاص', 'ayahs': 4},
    {'number': 113, 'name': 'Al-Falaq', 'arabicName': 'الفلق', 'ayahs': 5},
    {'number': 114, 'name': 'An-Nas', 'arabicName': 'الناس', 'ayahs': 6},
  ];

  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredSurahs = [];
  
  @override
  void initState() {
    super.initState();
    _filteredSurahs = List.from(_surahs);
    _loadAllQuranData();
    debugPrint("🚀 ReadSurahSelectPage initialized");
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _filterSurahs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSurahs = List.from(_surahs);
      } else {
        _filteredSurahs = _surahs.where((surah) {
          return surah['name'].toLowerCase().contains(query.toLowerCase()) ||
              surah['arabicName'].contains(query) ||
              surah['number'].toString() == query;
        }).toList();
      }
    });
  }

  Future<void> _loadAllQuranData() async {
    try {
      debugPrint("📚 Loading full Quran data from assets");
      final String jsonData =
          await rootBundle.loadString('assets/data/quran.json');
      debugPrint("📚 Quran JSON loaded, size: ${jsonData.length} bytes");
      
      final decoded = json.decode(jsonData);
      if (decoded is Map<String, dynamic>) {
        setState(() {
          allQuranData = decoded;
        });
        debugPrint("✅ Successfully loaded Quran data with ${allQuranData.length} surahs");
      } else {
        debugPrint("❌ Decoded JSON is not a Map: ${decoded.runtimeType}");
      }
    } catch (e) {
      debugPrint("❌ Error loading all Quran data: $e");
      debugPrintStack();
    }
  }

  Future<void> _toggleVoiceRecording() async {
    debugPrint("🎤 Toggle voice recording, current state: ${_isRecording ? 'recording' : 'not recording'}");
    if (_isRecording) {
      await _stopVoiceSearch();
    } else {
      await _startVoiceSearch();
    }
  }

  Future<void> _startVoiceSearch() async {
    if (_isRecording || _isProcessing) return;

    try {
      debugPrint("🎤 Checking microphone permission");
      bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint("❌ Microphone permission denied");
        setState(() {
          _voiceSearchStatus = 'Microphone permission denied';
        });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final recordingPath = path.join(
          tempDir.path, 'voice_search_${DateTime.now().millisecondsSinceEpoch}.wav');
      debugPrint("📁 Recording path set to: $recordingPath");

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 128000,
      );

      await _audioRecorder.start(config, path: recordingPath);
      debugPrint("🎙 Recording started with config: ${config.encoder}, ${config.sampleRate}Hz");

      setState(() {
        _isRecording = true;
        _voiceSearchStatus = 'Recording... Tap again to stop';
        _recordingPath = recordingPath;
      });
    } catch (e) {
      debugPrint("❌ Error starting recording: ${e.toString()}");
      setState(() {
        _voiceSearchStatus = 'Error starting recording: ${e.toString()}';
      });
    }
  }

  Future<void> _stopVoiceSearch() async {
    if (!_isRecording) return;

    try {
      debugPrint("🛑 Stopping recording");
      final path = await _audioRecorder.stop();
      debugPrint("📂 Recording saved to: $path");

      setState(() {
        _isRecording = false;
        _voiceSearchStatus = 'Processing voice search...';
      });

      if (path != null) {
        await _processVoiceSearchWithAPI(path);
      } else {
        debugPrint("❌ Recording path is null after stopping");
        setState(() {
          _voiceSearchStatus = 'Failed to save recording';
        });
      }
    } catch (e) {
      debugPrint("❌ Error stopping recording: ${e.toString()}");
      setState(() {
        _isRecording = false;
        _voiceSearchStatus = 'Error stopping recording: ${e.toString()}';
      });
    }
  }

  Future<void> _processVoiceSearchWithAPI(String path) async {
    setState(() {
      _isProcessing = true;
      _voiceSearchStatus = "Processing audio...";
    });

    debugPrint("🔍 Processing audio file: $path");
    final File audioFile = File(path);
    
    // Check if file exists
    if (!await audioFile.exists()) {
      debugPrint("❌ Audio file doesn't exist at path: $path");
      setState(() {
        _isProcessing = false;
        _voiceSearchStatus = "Error: Audio file not found";
      });
      return;
    }
    
    debugPrint("📊 Audio file size: ${await audioFile.length()} bytes");
    
    final List<int> audioBytes;

    try {
      audioBytes = await audioFile.readAsBytes();
      debugPrint("✓ Successfully read ${audioBytes.length} bytes from audio file");
    } catch (e) {
      debugPrint("❌ Error reading audio file: ${e.toString()}");
      setState(() {
        _isProcessing = false;
        _voiceSearchStatus = "Error reading audio file: ${e.toString()}";
      });
      return;
    }

    final headers = {
      "Authorization": "Bearer $_apiToken",
      "Content-Type": "audio/wav",
    };

    debugPrint("🌐 Sending request to API: $_apiUrl");
    debugPrint("🔑 Using token: ${_apiToken.substring(0, 5)}...${_apiToken.substring(_apiToken.length - 5)}");
    
    const int maxRetries = 4;
    const int initialDelayMs = 1000;
    int currentRetry = 0;
    bool success = false;

    while (currentRetry < maxRetries && !success) {
      try {
        if (currentRetry > 0) {
          debugPrint("🔄 Retry attempt ${currentRetry}/${maxRetries - 1}...");
          setState(() {
            _voiceSearchStatus = "Retry attempt ${currentRetry}/${maxRetries - 1}...";
          });
          final delayMs = initialDelayMs * (1 << (currentRetry - 1));
          await Future.delayed(Duration(milliseconds: delayMs));
        }

        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: headers,
          body: audioBytes,
        );

        debugPrint("📡 API response status code: ${response.statusCode}");
        debugPrint("📡 API response body length: ${response.body.length}");
        debugPrint("📡 Raw API response: ${response.body}");

        if (response.statusCode == 200) {
          try {
            final decodedResponse = jsonDecode(response.body);
            debugPrint("✓ Successfully decoded JSON response: ${decodedResponse.runtimeType}");
            debugPrint("📋 Decoded response structure: $decodedResponse");
            
            String transcribedText = '';
            
            if (decodedResponse is Map && decodedResponse.containsKey('text')) {
              transcribedText = decodedResponse['text'];
              debugPrint("📝 Found 'text' field in response map: $transcribedText");
            } else if (decodedResponse is List &&
                decodedResponse.isNotEmpty &&
                decodedResponse[0] is Map) {
              transcribedText = decodedResponse[0]['generated_text'] ?? '';
              debugPrint("📝 Found 'generated_text' field in response list: $transcribedText");
            } else {
              transcribedText = decodedResponse.toString();
              debugPrint("⚠️ Using fallback text extraction: $transcribedText");
            }

            debugPrint("🔤 Raw transcribed text before encoding fix: '$transcribedText'");
            debugPrint("🔤 Text bytes before encoding: ${transcribedText.codeUnits}");
            
            transcribedText = _fixArabicEncoding(transcribedText);
            debugPrint("🔤 After fixing Arabic encoding: '$transcribedText'");
            debugPrint("🔤 Text bytes after encoding: ${transcribedText.codeUnits}");

            setState(() {
              _isProcessing = false;
              _apiResult = transcribedText;
              _transcriptions.add(transcribedText);
              _voiceSearchStatus = "Searching for: $transcribedText";
            });

            success = true;
            
            // Search for the transcribed text in the Quran
            await _searchInQuran(transcribedText);
          } catch (e) {
            debugPrint("❌ Error parsing API response: ${e.toString()}");
            debugPrint("📜 Raw response: ${response.body}");
            setState(() {
              _isProcessing = false;
              _voiceSearchStatus = "Error parsing API response: ${e.toString()}";
            });
            break;
          }
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          debugPrint("⏳ API temporarily unavailable (${response.statusCode}), retrying...");
          currentRetry++;
        } else {
          debugPrint("❌ API error response: ${response.body}");
          setState(() {
            _isProcessing = false;
            _voiceSearchStatus = "API Error ${response.statusCode}: ${response.reasonPhrase}";
          });
          break;
        }
      } catch (e) {
        debugPrint("❌ Error making API request: ${e.toString()}");
        currentRetry++;
        if (currentRetry >= maxRetries) {
          setState(() {
            _isProcessing = false;
            _voiceSearchStatus = "Error processing audio after $maxRetries attempts: ${e.toString()}";
          });
        }
      }
    }

    if (!success && currentRetry >= maxRetries) {
      debugPrint("❌ API failed to respond after $maxRetries attempts");
      setState(() {
        _isProcessing = false;
        _voiceSearchStatus = "API failed to respond after $maxRetries attempts. The model may still be loading. Please try again in a minute.";
      });
    }
  }

  // Helper method to prepare text for comparison
  String _prepareTextForComparison(String text) {
    debugPrint("🧹 Preparing text for comparison: '$text'");
    
    // Use the same method as hifz page - normalize alef forms and basic normalization
    String result = text;

    // Normalize alef forms
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');

    // Remove diacritics (tashkeel)
    result = result.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');

    // Normalize whitespace
    result = result.trim();
    result = result.replaceAll(RegExp(r'\s+'), ' '); // Replace multiple spaces with single space

    debugPrint("🧹 Text after preparation: '$result'");
    return result;
  }

  // Helper method to fix Arabic encoding issues
  String _fixArabicEncoding(String text) {
    debugPrint("🔍 Original text before encoding fix: '$text'");
    debugPrint("🔍 Original text code units: ${text.codeUnits}");
    
    // Check if text contains encoding issues
    if (text.contains('Ù') || text.contains('Ø') || text.contains('Ú')) {
      debugPrint("🔧 Detected encoding issues, attempting to fix...");
      
      try {
        // Try using utf8.decode with latin1.encode (Method 1)
        debugPrint("🔧 Trying UTF8 decode with latin1 encode...");
        String result = utf8.decode(latin1.encode(text));
        debugPrint("✓ UTF8 decode result: '$result'");
        if (!result.contains('Ù') && !result.contains('Ø')) {
          debugPrint("✓ UTF8 decode successful!");
          return result.trim();
        }
      } catch (e) {
        debugPrint("❌ UTF8 decode failed: $e");
      }
      
      try {
        // Try another common approach (Method 2)
        debugPrint("🔧 Trying code unit adjustment...");
        final bytes = text.codeUnits.map((c) => c < 128 ? c : (c - 848)).toList();
        String result = String.fromCharCodes(bytes);
        debugPrint("✓ Code unit adjustment result: '$result'");
        if (!result.contains('Ù') && !result.contains('Ø')) {
          debugPrint("✓ Code unit adjustment successful!");
          return result.trim();
        }
      } catch (e) {
        debugPrint("❌ Code unit adjustment failed: $e");
      }
      
      // Fall back to manual replacement (Method 3)
      debugPrint("🔧 Falling back to manual character replacement...");
      final Map<String, String> replacements = {
        'Ø§': 'ا', 'Ø£': 'أ', 'Ø¢': 'آ', 'Ø¥': 'إ', 'Ø¨': 'ب', 'Øª': 'ت',
        'Ø«': 'ث', 'Ø¬': 'ج', 'Ø­': 'ح', 'Ø®': 'خ', 'Ø¯': 'د', 'Ø°': 'ذ',
        'Ø±': 'ر', 'Ø²': 'ز', 'Ø³': 'س', 'Ø´': 'ش', 'Øµ': 'ص', 'Ø¶': 'ض',
        'Ø·': 'ط', 'Ø¸': 'ظ', 'Ø¹': 'ع', 'Øº': 'غ', 'Ù': 'ف', 'Ù‚': 'ق',
        'Ùƒ': 'ك', 'Ù„': 'ل', 'Ù…': 'م', 'Ù†': 'ن', 'Ù‡': 'ه', 'Ùˆ': 'و',
        'ÙŠ': 'ي', 'Ø©': 'ة', 'Ø¡': 'ء', 'Ù‰': 'ى', 'ÙŽ': 'َ', 'Ù': 'ُ',
        'Ù': 'ِ', 'Ù‹': 'ً', 'ÙŒ': 'ٌ', 'Ù': 'ٍ', 'Ù': 'ّ', 'Ù': 'ْ',
      };

      String result = text;
      replacements.forEach((key, value) {
        result = result.replaceAll(key, value);
      });
      
      debugPrint("✓ Manual replacement result: '$result'");
      return result.trim();
    }
    
    debugPrint("✓ No encoding issues detected, returning original text");
    return text.trim();
  }

  // Search the Quran for matching text
  Future<void> _searchInQuran(String searchText) async {
    if (searchText.isEmpty) {
      debugPrint("❌ Empty search text, skipping search");
      return;
    }

    debugPrint("🔍 Starting Quran search for: '$searchText'");
    debugPrint("🔍 Search text length: ${searchText.length}");
    debugPrint("🔍 Search text code units: ${searchText.codeUnits}");
    debugPrint("📚 Number of surahs in Quran data: ${allQuranData.length}");
    
    if (allQuranData.isEmpty) {
      debugPrint("❗ Quran data is empty! Loading it now...");
      await _loadAllQuranData();
      if (allQuranData.isEmpty) {
        debugPrint("❌ Failed to load Quran data");
        setState(() {
          _voiceSearchStatus = "Error: Couldn't load Quran data";
          _isProcessing = false;
        });
        return;
      }
    }

    List<Map<String, dynamic>> results = [];
    int totalAyahsChecked = 0;
    int possibleMatches = 0;

    // Prepare search text for comparison using the same method as hifz page
    String cleanSearchText = _prepareTextForComparison(searchText);
    debugPrint("🧹 Cleaned search text: '$cleanSearchText'");
    debugPrint("🧹 Cleaned search text code units: ${cleanSearchText.codeUnits}");

    // Search through all surahs and ayahs
    allQuranData.forEach((surahNumber, surahData) {
      if (surahData is Map) {  // Make sure surahData is a Map
        surahData.forEach((ayahNumber, ayahData) {
          totalAyahsChecked++;
          
          if (ayahData is Map && (ayahData.containsKey('text') || ayahData.containsKey('displayText'))) {
            String ayahText = ayahData['text'] ?? '';
            String displayText = ayahData['displayText'] ?? ayahText;
            
            // Prepare ayah text for comparison using the same method as hifz page
            String cleanAyahText = _prepareTextForComparison(ayahText);
            String cleanDisplayText = _prepareTextForComparison(displayText);
            
            debugPrint("📖 Checking Surah $surahNumber, Ayah $ayahNumber");
            debugPrint("📖 Original ayah text: '$ayahText'");
            debugPrint("📖 Cleaned ayah text: '$cleanAyahText'");
            debugPrint("📖 Cleaned display text: '$cleanDisplayText'");
            
            // Calculate similarity using the same method as hifz page
            double similarity1 = _calculateMatchScore(cleanSearchText, cleanAyahText) / 100.0;
            double similarity2 = _calculateMatchScore(cleanSearchText, cleanDisplayText) / 100.0;
            double maxSimilarity = math.max(similarity1, similarity2);
            
            // Also check for direct substring matches
            bool containsMatch1 = cleanAyahText.contains(cleanSearchText);
            bool containsMatch2 = cleanDisplayText.contains(cleanSearchText);
            bool hasDirectMatch = containsMatch1 || containsMatch2;
            
            debugPrint("📊 Similarity scores: text=$similarity1, display=$similarity2, max=$maxSimilarity");
            debugPrint("📊 Direct matches: text=$containsMatch1, display=$containsMatch2");
            
            // Lower threshold for matching (30% similarity or direct match)
            if (hasDirectMatch || maxSimilarity > 0.3) {
              possibleMatches++;
              debugPrint("✓ Match found in Surah $surahNumber, Ayah $ayahNumber (similarity: ${maxSimilarity.toStringAsFixed(2)}, direct: $hasDirectMatch)");
              
              // Find the surah info
              final surahInfo = _surahs.firstWhere(
                (s) => s['number'] == int.parse(surahNumber),
                orElse: () => {'name': 'Unknown', 'arabicName': 'غير معروف', 'number': int.parse(surahNumber), 'ayahs': 0},
              );
              
              results.add({
                'surahNumber': int.parse(surahNumber),
                'ayahNumber': int.parse(ayahNumber),
                'text': displayText,
                'plainText': ayahText,
                'surahName': surahInfo['name'],
                'surahArabicName': surahInfo['arabicName'],
                'similarity': maxSimilarity,
                'hasDirectMatch': hasDirectMatch,
              });
            }
          }
        });
      } else {
        debugPrint("⚠️ Invalid surah data format for surah $surahNumber");
      }
    });

    // Sort by direct matches first, then by similarity score (highest first)
    results.sort((a, b) {
      // Direct matches come first
      if (a['hasDirectMatch'] && !b['hasDirectMatch']) return -1;
      if (!a['hasDirectMatch'] && b['hasDirectMatch']) return 1;
      // Then sort by similarity
      return b['similarity'].compareTo(a['similarity']);
    });
    
    debugPrint("📊 Search stats: Checked $totalAyahsChecked ayahs, found $possibleMatches possible matches");
    debugPrint("🔍 Final results count: ${results.length}");
    
    if (results.isNotEmpty) {
      debugPrint("✨ Top match: Surah ${results[0]['surahNumber']}, Ayah ${results[0]['ayahNumber']}, similarity: ${results[0]['similarity'].toStringAsFixed(2)}, direct: ${results[0]['hasDirectMatch']}");
      
      // Log the first few results for debugging
      for (int i = 0; i < math.min(3, results.length); i++) {
        final result = results[i];
        debugPrint("🏆 Result ${i + 1}: Surah ${result['surahNumber']}, Ayah ${result['ayahNumber']}, similarity: ${result['similarity'].toStringAsFixed(2)}");
        
        // Fix the type issue by explicitly handling the text as a String
        final text = result['text'] as String;
        final previewLength = math.min(50, text.length);
        debugPrint("🏆 Result ${i + 1} text: '${text.substring(0, previewLength)}...'");
      }
    } else {
      debugPrint("❌ No matches found for search text: '$searchText'");
    }

    setState(() {
      searchResults = results;
      _showSearchResults = true; // Always show the search results view, even if empty
      _voiceSearchStatus = results.isNotEmpty 
          ? "Found ${results.length} matching ayahs"
          : "No matching ayahs found for: '$searchText'";
      _isProcessing = false;
    });
  }

  int _calculateMatchScore(String transcription, String original) {
    debugPrint("📊 Calculating match score between:");
    debugPrint("📊   Transcription: '$transcription'");
    debugPrint("📊   Original: '$original'");
    
    List<String> originalWords = original.split(' ');
    List<String> transcriptionWords = transcription.split(' ');

    debugPrint("📊 Original words (${originalWords.length}): $originalWords");
    debugPrint("📊 Transcription words (${transcriptionWords.length}): $transcriptionWords");

    int correctWords = 0;

    // More precise matching - compare each word
    for (int i = 0; i < transcriptionWords.length; i++) {
      if (i < originalWords.length) {
        bool matches = transcriptionWords[i] == originalWords[i];
        debugPrint("📊 Word $i: '${transcriptionWords[i]}' vs '${originalWords[i]}' = $matches");
        if (matches) {
          correctWords++;
        }
      }
    }

    int totalWords = math.max(originalWords.length, transcriptionWords.length);
    if (totalWords == 0) return 0;

    int score = (correctWords * 100 ~/ totalWords);
    debugPrint("📊 Final score: $correctWords/$totalWords = $score%");
    
    return score;
  }

  void _navigateToAyah(Map<String, dynamic> ayah) {
    debugPrint("🔍 Navigating to Surah ${ayah['surahNumber']}, Ayah ${ayah['ayahNumber']}");
    
    // Create a consistent surah info object with all required fields
    final Map<String, dynamic> surahInfo = {
      'surahNumber': ayah['surahNumber'],
      'surahName': ayah['surahName'],
      'arabicName': ayah['surahArabicName'],
      'ayahCount': _surahs.firstWhere(
        (s) => s['number'] == ayah['surahNumber'],
        orElse: () => {'ayahs': 0},
      )['ayahs'],
    };
    
    debugPrint("🔍 Navigation info: $surahInfo");
    
    // Pass surahInfo directly instead of nesting it
    Navigator.pushNamed(
      context,
      '/read_quran',
      arguments: surahInfo,
    );
    
    // Hide the search results
    setState(() {
      _showSearchResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Surah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Voice search button
          IconButton(
            icon: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: _isRecording ? Colors.red : Colors.white,
            ),
            tooltip: 'Search by voice',
            onPressed: _toggleVoiceRecording,
          ),
          // Text search field
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SurahSearchDelegate(_surahs, (surahInfo) {
                  // Pass surahInfo directly instead of nesting it
                  Navigator.pushNamed(
                    context,
                    '/read_quran',
                    arguments: surahInfo,
                  );
                }),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF00A896),
        elevation: 0, // Match the Hifz page's elevation
      ),
      body: _showSearchResults 
          ? _buildSearchResults() 
          : _buildSurahList(), // Use list instead of grid to match Hifz page
    );
  }

  // New method to build surah list similar to HifzSelectSurahPage
  Widget _buildSurahList() {
    return Column(
      children: [
        // Search bar with styling matching HifzSelectSurahPage
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: _filterSurahs,
            decoration: InputDecoration(
              hintText: 'Search surah...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00A896), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ),

        // Voice search status text (keep this from the original implementation)
        if (_isRecording || _isProcessing)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isRecording ? Colors.red : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (_isProcessing)
                  const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isRecording ? Icons.mic : Icons.hourglass_top,
                    color: _isRecording ? Colors.red : Colors.orange,
                    size: 16,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _voiceSearchStatus,
                    style: TextStyle(
                      fontSize: 13,
                      color: _isRecording ? Colors.red : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // List of surahs styled like HifzSelectSurahPage
        Expanded(
          child: ListView.builder(
            itemCount: _filteredSurahs.length,
            itemBuilder: (context, index) {
              final surah = _filteredSurahs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    child: Text(surah['number'].toString()),
                  ),
                  title: Text(
                    surah['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "${surah['ayahs']} Ayahs",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Text(
                    surah['arabicName'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Scheherazade',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  onTap: () {
                    // Create surah info and navigate
                    final Map<String, dynamic> surahInfo = {
                      'surahNumber': surah['number'],
                      'surahName': surah['name'],
                      'arabicName': surah['arabicName'],
                      'ayahCount': surah['ayahs'],
                    };
                    
                    // Add debugging
                    debugPrint("🔍 Navigating to surah: ${surahInfo['surahNumber']} - ${surahInfo['surahName']}");
                    
                    // Pass surahInfo directly
                    Navigator.pushNamed(
                      context,
                      '/read_quran',
                      arguments: surahInfo,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    debugPrint("🔍 Building search results view with ${searchResults.length} results");
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00A896).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Voice search status
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isProcessing 
                  ? Colors.orange.withOpacity(0.1)
                  : searchResults.isEmpty 
                      ? Colors.red.withOpacity(0.1) 
                      : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isProcessing 
                    ? Colors.orange 
                    : searchResults.isEmpty 
                        ? Colors.red 
                        : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (_isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    searchResults.isEmpty ? Icons.search_off : Icons.search,
                    color: searchResults.isEmpty ? Colors.red : Colors.green,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _voiceSearchStatus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isProcessing 
                          ? Colors.orange 
                          : searchResults.isEmpty 
                              ? Colors.red 
                              : Colors.green,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    debugPrint("🔍 Closing search results");
                    setState(() {
                      _showSearchResults = false;
                      searchResults.clear();
                      _voiceSearchStatus = 'Tap microphone to search by voice';
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Search results list or empty state
          Expanded(
            child: searchResults.isEmpty && !_isProcessing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No matches found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            "Try a different phrase or tap the microphone to search again",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final ayah = searchResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        // Change card background to white
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            debugPrint("🔍 User selected result: Surah ${ayah['surahNumber']}, Ayah ${ayah['ayahNumber']}");
                            _navigateToAyah(ayah);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Surah and Ayah info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8, 
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00A896),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Surah ${ayah['surahNumber']}, Ayah ${ayah['ayahNumber']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ayah['surahName'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Color(0xFF00A896),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Ayah text
                                Text(
                                  ayah['text'],
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Scheherazade',
                                    height: 1.8,
                                    color: Colors.black87, // Ensure text is dark for good contrast on white
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}