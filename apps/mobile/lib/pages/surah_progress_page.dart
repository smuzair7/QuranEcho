import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../services/surah_progress_service.dart';

class SurahProgressPage extends StatefulWidget {
  const SurahProgressPage({super.key});

  @override
  State<SurahProgressPage> createState() => _SurahProgressPageState();
}

class _SurahProgressPageState extends State<SurahProgressPage> {
  // List of all 114 Surahs with their names and total ayats
  final List<Map<String, dynamic>> _surahs = [
    {'name': 'Al-Fatiha', 'totalAyats': 7, 'number': 1},
    {'name': 'Al-Baqarah', 'totalAyats': 286, 'number': 2},
    {'name': 'Ali Imran', 'totalAyats': 200, 'number': 3},
    {'name': 'An-Nisa', 'totalAyats': 176, 'number': 4},
    {'name': 'Al-Maidah', 'totalAyats': 120, 'number': 5},
    {'name': 'Al-Anam', 'totalAyats': 165, 'number': 6},
    {'name': 'Al-Araf', 'totalAyats': 206, 'number': 7},
    {'name': 'Al-Anfal', 'totalAyats': 75, 'number': 8},
    {'name': 'At-Tawbah', 'totalAyats': 129, 'number': 9},
    {'name': 'Yunus', 'totalAyats': 109, 'number': 10},
    {'name': 'Hud', 'totalAyats': 123, 'number': 11},
    {'name': 'Yusuf', 'totalAyats': 111, 'number': 12},
    {'name': 'Ar-Rad', 'totalAyats': 43, 'number': 13},
    {'name': 'Ibrahim', 'totalAyats': 52, 'number': 14},
    {'name': 'Al-Hijr', 'totalAyats': 99, 'number': 15},
    {'name': 'An-Nahl', 'totalAyats': 128, 'number': 16},
    {'name': 'Al-Isra', 'totalAyats': 111, 'number': 17},
    {'name': 'Al-Kahf', 'totalAyats': 110, 'number': 18},
    {'name': 'Maryam', 'totalAyats': 98, 'number': 19},
    {'name': 'Ta-Ha', 'totalAyats': 135, 'number': 20},
    {'name': 'Al-Anbiya', 'totalAyats': 112, 'number': 21},
    {'name': 'Al-Hajj', 'totalAyats': 78, 'number': 22},
    {'name': 'Al-Muminun', 'totalAyats': 118, 'number': 23},
    {'name': 'An-Nur', 'totalAyats': 64, 'number': 24},
    {'name': 'Al-Furqan', 'totalAyats': 77, 'number': 25},
    {'name': 'Ash-Shuara', 'totalAyats': 227, 'number': 26},
    {'name': 'An-Naml', 'totalAyats': 93, 'number': 27},
    {'name': 'Al-Qasas', 'totalAyats': 88, 'number': 28},
    {'name': 'Al-Ankabut', 'totalAyats': 69, 'number': 29},
    {'name': 'Ar-Rum', 'totalAyats': 60, 'number': 30},
    {'name': 'Luqman', 'totalAyats': 34, 'number': 31},
    {'name': 'As-Sajdah', 'totalAyats': 30, 'number': 32},
    {'name': 'Al-Ahzab', 'totalAyats': 73, 'number': 33},
    {'name': 'Saba', 'totalAyats': 54, 'number': 34},
    {'name': 'Fatir', 'totalAyats': 45, 'number': 35},
    {'name': 'Ya-Sin', 'totalAyats': 83, 'number': 36},
    {'name': 'As-Saffat', 'totalAyats': 182, 'number': 37},
    {'name': 'Sad', 'totalAyats': 88, 'number': 38},
    {'name': 'Az-Zumar', 'totalAyats': 75, 'number': 39},
    {'name': 'Ghafir', 'totalAyats': 85, 'number': 40},
    {'name': 'Fussilat', 'totalAyats': 54, 'number': 41},
    {'name': 'Ash-Shura', 'totalAyats': 53, 'number': 42},
    {'name': 'Az-Zukhruf', 'totalAyats': 89, 'number': 43},
    {'name': 'Ad-Dukhan', 'totalAyats': 59, 'number': 44},
    {'name': 'Al-Jathiyah', 'totalAyats': 37, 'number': 45},
    {'name': 'Al-Ahqaf', 'totalAyats': 35, 'number': 46},
    {'name': 'Muhammad', 'totalAyats': 38, 'number': 47},
    {'name': 'Al-Fath', 'totalAyats': 29, 'number': 48},
    {'name': 'Al-Hujurat', 'totalAyats': 18, 'number': 49},
    {'name': 'Qaf', 'totalAyats': 45, 'number': 50},
    {'name': 'Adh-Dhariyat', 'totalAyats': 60, 'number': 51},
    {'name': 'At-Tur', 'totalAyats': 49, 'number': 52},
    {'name': 'An-Najm', 'totalAyats': 62, 'number': 53},
    {'name': 'Al-Qamar', 'totalAyats': 55, 'number': 54},
    {'name': 'Ar-Rahman', 'totalAyats': 78, 'number': 55},
    {'name': 'Al-Waqiah', 'totalAyats': 96, 'number': 56},
    {'name': 'Al-Hadid', 'totalAyats': 29, 'number': 57},
    {'name': 'Al-Mujadila', 'totalAyats': 22, 'number': 58},
    {'name': 'Al-Hashr', 'totalAyats': 24, 'number': 59},
    {'name': 'Al-Mumtahanah', 'totalAyats': 13, 'number': 60},
    {'name': 'As-Saff', 'totalAyats': 14, 'number': 61},
    {'name': 'Al-Jumuah', 'totalAyats': 11, 'number': 62},
    {'name': 'Al-Munafiqun', 'totalAyats': 11, 'number': 63},
    {'name': 'At-Taghabun', 'totalAyats': 18, 'number': 64},
    {'name': 'At-Talaq', 'totalAyats': 12, 'number': 65},
    {'name': 'At-Tahrim', 'totalAyats': 12, 'number': 66},
    {'name': 'Al-Mulk', 'totalAyats': 30, 'number': 67},
    {'name': 'Al-Qalam', 'totalAyats': 52, 'number': 68},
    {'name': 'Al-Haqqah', 'totalAyats': 52, 'number': 69},
    {'name': 'Al-Maarij', 'totalAyats': 44, 'number': 70},
    {'name': 'Nuh', 'totalAyats': 28, 'number': 71},
    {'name': 'Al-Jinn', 'totalAyats': 28, 'number': 72},
    {'name': 'Al-Muzzammil', 'totalAyats': 20, 'number': 73},
    {'name': 'Al-Muddaththir', 'totalAyats': 56, 'number': 74},
    {'name': 'Al-Qiyamah', 'totalAyats': 40, 'number': 75},
    {'name': 'Al-Insan', 'totalAyats': 31, 'number': 76},
    {'name': 'Al-Mursalat', 'totalAyats': 50, 'number': 77},
    {'name': 'An-Naba', 'totalAyats': 40, 'number': 78},
    {'name': 'An-Naziat', 'totalAyats': 46, 'number': 79},
    {'name': 'Abasa', 'totalAyats': 42, 'number': 80},
    {'name': 'At-Takwir', 'totalAyats': 29, 'number': 81},
    {'name': 'Al-Infitar', 'totalAyats': 19, 'number': 82},
    {'name': 'Al-Mutaffifin', 'totalAyats': 36, 'number': 83},
    {'name': 'Al-Inshiqaq', 'totalAyats': 25, 'number': 84},
    {'name': 'Al-Buruj', 'totalAyats': 22, 'number': 85},
    {'name': 'At-Tariq', 'totalAyats': 17, 'number': 86},
    {'name': 'Al-Ala', 'totalAyats': 19, 'number': 87},
    {'name': 'Al-Ghashiyah', 'totalAyats': 26, 'number': 88},
    {'name': 'Al-Fajr', 'totalAyats': 30, 'number': 89},
    {'name': 'Al-Balad', 'totalAyats': 20, 'number': 90},
    {'name': 'Ash-Shams', 'totalAyats': 15, 'number': 91},
    {'name': 'Al-Layl', 'totalAyats': 21, 'number': 92},
    {'name': 'Ad-Duha', 'totalAyats': 11, 'number': 93},
    {'name': 'Ash-Sharh', 'totalAyats': 8, 'number': 94},
    {'name': 'At-Tin', 'totalAyats': 8, 'number': 95},
    {'name': 'Al-Alaq', 'totalAyats': 19, 'number': 96},
    {'name': 'Al-Qadr', 'totalAyats': 5, 'number': 97},
    {'name': 'Al-Bayyinah', 'totalAyats': 8, 'number': 98},
    {'name': 'Az-Zalzalah', 'totalAyats': 8, 'number': 99},
    {'name': 'Al-Adiyat', 'totalAyats': 11, 'number': 100},
    {'name': 'Al-Qariah', 'totalAyats': 11, 'number': 101},
    {'name': 'At-Takathur', 'totalAyats': 8, 'number': 102},
    {'name': 'Al-Asr', 'totalAyats': 3, 'number': 103},
    {'name': 'Al-Humazah', 'totalAyats': 9, 'number': 104},
    {'name': 'Al-Fil', 'totalAyats': 5, 'number': 105},
    {'name': 'Quraysh', 'totalAyats': 4, 'number': 106},
    {'name': 'Al-Maun', 'totalAyats': 7, 'number': 107},
    {'name': 'Al-Kawthar', 'totalAyats': 3, 'number': 108},
    {'name': 'Al-Kafirun', 'totalAyats': 6, 'number': 109},
    {'name': 'An-Nasr', 'totalAyats': 3, 'number': 110},
    {'name': 'Al-Masad', 'totalAyats': 5, 'number': 111},
    {'name': 'Al-Ikhlas', 'totalAyats': 4, 'number': 112},
    {'name': 'Al-Falaq', 'totalAyats': 5, 'number': 113},
    {'name': 'An-Nas', 'totalAyats': 6, 'number': 114},
  ];

  // Services
  final SurahProgressService _surahProgressService = SurahProgressService();
  
  // Loading state
  bool _isLoading = true;
  String _error = '';
  
  // Dynamic data from database
  Map<int, int> _surahProgress = {}; // surahNumber -> memorizedAyats
  
  @override
  void initState() {
    super.initState();
    _loadSurahProgress();
  }

  // Load surah progress from database
  void _loadSurahProgress() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (!userProvider.isLoggedIn || userProvider.userId == null) {
      setState(() {
        _error = 'Please log in to view your progress';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('Loading surah progress for user: ${userProvider.userId}');
      final result = await _surahProgressService.getUserSurahProgress(userProvider.userId!);
      
      if (result['success']) {
        final progressData = result['data']['surahProgress'] ?? {};
        print('Received surah progress data: $progressData');
        
        // Convert progress data to Map<int, int>
        final Map<int, int> progress = {};
        if (progressData is Map) {
          progressData.forEach((key, value) {
            final surahNumber = int.tryParse(key.toString());
            if (surahNumber != null && value is Map) {
              final memorizedAyats = value['memorizedAyats'] ?? 0;
              progress[surahNumber] = memorizedAyats;
            }
          });
        }
        
        print('Processed surah progress: $progress');
        
        setState(() {
          _surahProgress = progress;
          _isLoading = false;
          _error = '';
        });
        
        // Show success message if this was a manual refresh
        if (mounted && progress.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('API failed: ${result['message']}');
        setState(() {
          _error = result['message'] ?? 'Failed to load progress';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception loading surah progress: ${e.toString()}');
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Show loading indicator
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Surah Progress'),
          backgroundColor: const Color(0xFF00A896),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF00A896),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading your progress...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error message
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Surah Progress'),
          backgroundColor: const Color(0xFF00A896),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Failed to load progress',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loadSurahProgress,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Calculate progress statistics
    final completedSurahs = _getCompletedSurahs();
    final partiallySurahs = _getPartiallySurahs();
    final notStartedCount = 114 - completedSurahs.length - partiallySurahs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surah Progress'),
        backgroundColor: const Color(0xFF00A896),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Manual refresh triggered');
              _loadSurahProgress();
            },
            tooltip: 'Refresh progress',
          ),
        ],
      ),
      body: Container(
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
        child: Column(
          children: [
            // Progress Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryCard(
                    'Completed',
                    completedSurahs.length.toString(),
                    const Color(0xFF00A896),
                    Icons.check_circle,
                  ),
                  _buildSummaryCard(
                    'In Progress',
                    partiallySurahs.length.toString(),
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                  _buildSummaryCard(
                    'Not Started',
                    notStartedCount.toString(),
                    Colors.grey,
                    Icons.circle_outlined,
                  ),
                ],
              ),
            ),
            
            // Progress info text
            if (_surahProgress.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Start memorizing ayats to track your surah progress here!',
                          style: TextStyle(
                            color: Colors.blue[200],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Surah List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  print('Pull to refresh triggered');
                  _loadSurahProgress();
                },
                color: const Color(0xFF00A896),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _surahs.length,
                  itemBuilder: (context, index) {
                    final surah = _surahs[index];
                    final surahNumber = surah['number'] as int;
                    final memorizedAyats = _surahProgress[surahNumber] ?? 0;
                    final totalAyats = surah['totalAyats'] as int;
                    
                    final isCompleted = memorizedAyats >= totalAyats;
                    final isPartial = memorizedAyats > 0 && memorizedAyats < totalAyats;
                    
                    return _buildSurahCard(
                      surah: surah,
                      isCompleted: isCompleted,
                      isPartial: isPartial,
                      memorizedAyats: memorizedAyats,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildSurahCard({
    required Map<String, dynamic> surah,
    required bool isCompleted,
    required bool isPartial,
    required int memorizedAyats,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isCompleted) {
      statusColor = const Color(0xFF00A896);
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (isPartial) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'In Progress';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.circle_outlined;
      statusText = 'Not Started';
    }

    final totalAyats = surah['totalAyats'] as int;
    final progressPercentage = totalAyats > 0 ? (memorizedAyats / totalAyats) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Surah Number
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        surah['number'].toString(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Surah Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$memorizedAyats/${surah['totalAyats']} Ayats',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Progress Bar (only show if partially completed)
              if (isPartial) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progressPercentage * 100).toInt()}% Complete',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Get completed surahs from real data
  Set<int> _getCompletedSurahs() {
    Set<int> completed = {};
    
    for (final surah in _surahs) {
      final surahNumber = surah['number'] as int;
      final totalAyats = surah['totalAyats'] as int;
      final memorizedAyats = _surahProgress[surahNumber] ?? 0;
      
      if (memorizedAyats >= totalAyats) {
        completed.add(surahNumber);
      }
    }
    
    return completed;
  }

  Set<int> _getPartiallySurahs() {
    Set<int> partial = {};
    
    for (final surah in _surahs) {
      final surahNumber = surah['number'] as int;
      final totalAyats = surah['totalAyats'] as int;
      final memorizedAyats = _surahProgress[surahNumber] ?? 0;
      
      if (memorizedAyats > 0 && memorizedAyats < totalAyats) {
        partial.add(surahNumber);
      }
    }
    
    return partial;
  }
}