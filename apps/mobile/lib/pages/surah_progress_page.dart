import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../services/surah_progress_service.dart';
import '../theme/app_theme.dart';

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
        backgroundColor: AppColors.parchment,
        appBar: AppBar(title: const Text('Surah Progress')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text(
                'Loading your progress...',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(title: const Text('Surah Progress')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.clay,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _loadSurahProgress,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
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
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: const Text('Surah Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              print('Manual refresh triggered');
              _loadSurahProgress();
            },
            tooltip: 'Refresh progress',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      'Completed',
                      completedSurahs.length.toString(),
                      AppColors.palm,
                      Icons.check_circle_rounded,
                    ),
                    _buildSummaryCard(
                      'In progress',
                      partiallySurahs.length.toString(),
                      AppColors.sage,
                      Icons.hourglass_bottom_rounded,
                    ),
                    _buildSummaryCard(
                      'Not started',
                      notStartedCount.toString(),
                      AppColors.inkSoft,
                      Icons.circle_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress info text
          if (_surahProgress.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.palmSoft,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.palm,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Start memorizing ayats to track your surah progress here!',
                        style: TextStyle(
                          color: AppColors.palmDeep,
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
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
      statusColor = AppColors.palm;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Completed';
    } else if (isPartial) {
      statusColor = AppColors.sage;
      statusIcon = Icons.hourglass_bottom_rounded;
      statusText = 'In progress';
    } else {
      statusColor = AppColors.inkSoft;
      statusIcon = Icons.circle_outlined;
      statusText = 'Not started';
    }

    final totalAyats = surah['totalAyats'] as int;
    final progressPercentage = totalAyats > 0 ? (memorizedAyats / totalAyats) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  // Surah Number
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        surah['number'].toString(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Surah Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(surah['name'], style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '$memorizedAyats/${surah['totalAyats']} ayats',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Progress Bar (only show if partially completed)
              if (isPartial) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(progressPercentage * 100).toInt()}% complete',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
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