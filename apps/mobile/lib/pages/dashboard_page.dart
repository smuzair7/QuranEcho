import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../services/user_stats_service.dart';
import 'login_page.dart';
import 'surah_progress_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // State variables for user stats
  int _memorizedAyats = 0;
  int _memorizedSurahs = 0;
  int _timeSpentMinutes = 0;
  int _dailyGoal = 10;
  int _streakDays = 0;
  List<int> _weeklyProgress = [0, 0, 0, 0, 0, 0, 0];

  // Services
  final UserStatsService _userStatsService = UserStatsService();

  // Controller for updating daily goal
  final TextEditingController _goalController = TextEditingController();

  // Loading state
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUserStats();

    // Add this to reload stats when the page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This ensures stats are reloaded when returning to this page
      print('Dashboard became visible - reloading stats');
      _loadUserStats();
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  // Load user stats from server
  void _loadUserStats() async {
    print('Loading user stats for dashboard...');
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Only load stats if user is logged in AND userId is not null
    if (userProvider.isLoggedIn && userProvider.userId != null) {
      final userIdValue = userProvider.userId!;

      print('Found logged in user with ID: $userIdValue');
      // Validate user ID - should be a MongoDB ObjectId (24 character hex string)
      if (userIdValue.isEmpty || userIdValue.length != 24) {
        print('Error: Invalid user ID format in provider: $userIdValue');
        setState(() {
          _error = 'Invalid user ID format. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        print('Requesting fresh stats from server for user: $userIdValue');
        final result = await _userStatsService.getUserStats(userIdValue);

        if (result['success']) {
          final stats = result['data'];
          print('Received stats from server: ${stats.toString()}');

          setState(() {
            _memorizedAyats = stats['memorizedAyats'] ?? 0;
            _memorizedSurahs = stats['memorizedSurahs'] ?? 0;
            _timeSpentMinutes = stats['timeSpentMinutes'] ?? 0;
            _dailyGoal = stats['dailyGoal'] ?? 10;
            _streakDays = stats['streakDays'] ?? 0;
            _weeklyProgress = List<int>.from(stats['weeklyProgress'] ?? [0, 0, 0, 0, 0, 0, 0]);
            _goalController.text = _dailyGoal.toString();
            _isLoading = false;
          });

          // Update user provider with latest stats
          await userProvider.updateUserStats(stats);
          print('Updated UserProvider with fresh stats');
        } else {
          print('Failed to load stats: ${result['message']}');
          setState(() {
            _error = result['message'] ?? 'Failed to load user stats';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading stats: ${e.toString()}');
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    } else {
      // If user is logged in but userId is null, show an error
      if (userProvider.isLoggedIn && userProvider.userId == null) {
        setState(() {
          _error = 'User ID is missing. Please try logging in again.';
          _isLoading = false;
        });
        return;
      }

      // If user stats are already in provider, use those
      if (userProvider.userStats != null) {
        final stats = userProvider.userStats!;
        setState(() {
          _memorizedAyats = stats['memorizedAyats'] ?? 0;
          _memorizedSurahs = stats['memorizedSurahs'] ?? 0;
          _timeSpentMinutes = stats['timeSpentMinutes'] ?? 0;
          _dailyGoal = stats['dailyGoal'] ?? 10;
          _streakDays = stats['streakDays'] ?? 0;
          _weeklyProgress = List<int>.from(stats['weeklyProgress'] ?? [0, 0, 0, 0, 0, 0, 0]);
          _goalController.text = _dailyGoal.toString();
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimeSpent(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours hrs $remainingMinutes mins';
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set daily goal'),
          content: TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ayats per day',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateDailyGoal(context),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Update daily goal on the server
  void _updateDailyGoal(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.isLoggedIn && userProvider.userId != null) {
      final userIdValue = userProvider.userId!;

      // Validate user ID
      if (userIdValue.isEmpty) {
        print('Error: Empty user ID in provider');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session error. Please log in again.')),
        );
        Navigator.pop(context);
        return;
      }

      final newGoal = int.tryParse(_goalController.text) ?? _dailyGoal;

      if (newGoal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal must be a positive number')),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating goal...')),
      );

      try {
        print('Updating goal to $newGoal for user ID: $userIdValue');
        final result = await _userStatsService.updateDailyGoal(
          userIdValue,
          newGoal,
        );

        if (result['success']) {
          setState(() {
            _dailyGoal = newGoal;
          });

          // Update user provider with new stats
          if (userProvider.userStats != null) {
            final updatedStats = Map<String, dynamic>.from(userProvider.userStats!);
            updatedStats['dailyGoal'] = newGoal;
            await userProvider.updateUserStats(updatedStats);
          }

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily goal updated')),
          );
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to update daily goal')),
          );
        }
      } catch (e) {
        print('Exception updating goal: ${e.toString()}');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update your goal')),
      );
    }
  }

  // Add method to get dynamic achievements based on user stats
  List<Map<String, dynamic>> _getAchievements() {
    return [
      {
        'icon': Icons.auto_stories,
        'title': 'First Step',
        'description': 'Memorize your first ayat',
        'isCompleted': _memorizedAyats >= 1,
        'progress': _memorizedAyats >= 1 ? 1.0 : _memorizedAyats / 1.0,
        'requirement': 1,
        'current': _memorizedAyats,
        'type': 'ayats'
      },
      {
        'icon': Icons.book,
        'title': 'Ayat Collector',
        'description': 'Memorize 10 ayats',
        'isCompleted': _memorizedAyats >= 10,
        'progress': _memorizedAyats >= 10 ? 1.0 : _memorizedAyats / 10.0,
        'requirement': 10,
        'current': _memorizedAyats,
        'type': 'ayats'
      },
      {
        'icon': Icons.bookmark,
        'title': 'Surah Beginner',
        'description': 'Complete your first surah',
        'isCompleted': _memorizedSurahs >= 1,
        'progress': _memorizedSurahs >= 1 ? 1.0 : _memorizedSurahs / 1.0,
        'requirement': 1,
        'current': _memorizedSurahs,
        'type': 'surahs'
      },
      {
        'icon': Icons.library_books,
        'title': 'Surah Master',
        'description': 'Complete 5 surahs',
        'isCompleted': _memorizedSurahs >= 5,
        'progress': _memorizedSurahs >= 5 ? 1.0 : _memorizedSurahs / 5.0,
        'requirement': 5,
        'current': _memorizedSurahs,
        'type': 'surahs'
      },
      {
        'icon': Icons.local_fire_department,
        'title': 'Consistent Learner',
        'description': 'Maintain a 7-day streak',
        'isCompleted': _streakDays >= 7,
        'progress': _streakDays >= 7 ? 1.0 : _streakDays / 7.0,
        'requirement': 7,
        'current': _streakDays,
        'type': 'streak'
      },
      {
        'icon': Icons.timer,
        'title': 'Time Devotee',
        'description': 'Spend 5+ hours learning',
        'isCompleted': _timeSpentMinutes >= 300,
        'progress': _timeSpentMinutes >= 300 ? 1.0 : _timeSpentMinutes / 300.0,
        'requirement': 300,
        'current': _timeSpentMinutes,
        'type': 'time'
      },
      {
        'icon': Icons.military_tech,
        'title': 'Hifz Scholar',
        'description': 'Complete 10 surahs',
        'isCompleted': _memorizedSurahs >= 10,
        'progress': _memorizedSurahs >= 10 ? 1.0 : _memorizedSurahs / 10.0,
        'requirement': 10,
        'current': _memorizedSurahs,
        'type': 'surahs'
      },
      {
        'icon': Icons.stars,
        'title': 'Dedication Master',
        'description': 'Memorize 50+ ayats',
        'isCompleted': _memorizedAyats >= 50,
        'progress': _memorizedAyats >= 50 ? 1.0 : _memorizedAyats / 50.0,
        'requirement': 50,
        'current': _memorizedAyats,
        'type': 'ayats'
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // If user is not logged in, show login prompt
    if (!userProvider.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.palmSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.palm),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Log in to view your dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading indicator while fetching data
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if there was an error loading data
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(title: const Text('Dashboard')),
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
                  'Couldn’t load dashboard data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _loadUserStats,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User is logged in, show dashboard
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
            onPressed: () {
              // Show loading indicator while refreshing
              setState(() {
                _isLoading = true;
              });
              _loadUserStats();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadUserStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.palm,
                          child: Text(
                            userProvider.username?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.parchment,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProvider.username ?? 'User',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded,
                                      color: AppColors.gold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_streakDays day streak',
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Stats Grid
                Text('Your progress', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      title: 'Memorized ayats',
                      value: _memorizedAyats.toString(),
                      icon: Icons.auto_stories_rounded,
                      color: AppColors.palm,
                    ),
                    _buildClickableStatCard(
                      title: 'Completed surahs',
                      value: _memorizedSurahs.toString(),
                      icon: Icons.bookmark_rounded,
                      color: AppColors.sage,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SurahProgressPage(),
                          ),
                        );
                      },
                    ),
                    _buildStatCard(
                      title: 'Time spent',
                      value: _formatTimeSpent(_timeSpentMinutes),
                      icon: Icons.timer_rounded,
                      color: AppColors.palmDeep,
                    ),
                    _buildGoalCard(
                      title: 'Daily goal',
                      value: '$_dailyGoal ayats/day',
                      icon: Icons.flag_rounded,
                      color: AppColors.gold,
                      onTap: _showGoalDialog,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Weekly Progress Chart
                Text('Weekly progress', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Container(
                    height: 250,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ayats memorized: last 7 days',
                          style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _weeklyProgress.isEmpty
                                  ? 10
                                  : (_weeklyProgress.reduce((a, b) => a > b ? a : b) * 1.2),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                                        return Text(
                                          days[value.toInt()],
                                          style: const TextStyle(
                                            color: AppColors.inkSoft,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 5 == 0) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: AppColors.inkSoft,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 5,
                                getDrawingHorizontalLine: (value) {
                                  return const FlLine(
                                    color: AppColors.line,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: _weeklyProgress.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.toDouble(),
                                      color: entry.value >= _dailyGoal
                                          ? AppColors.palm
                                          : AppColors.sage,
                                      width: 16,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Achievement Section
                Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: _getAchievements().map((achievement) => _buildAchievementItem(
                        icon: achievement['icon'],
                        title: achievement['title'],
                        description: achievement['description'],
                        isCompleted: achievement['isCompleted'],
                        progress: achievement['progress'],
                        requirement: achievement['requirement'],
                        current: achievement['current'],
                        type: achievement['type'],
                      )).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBorder,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 26, color: color),
                  const Icon(Icons.edit_rounded, size: 16, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBorder,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 26, color: color),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required double progress,
    required int requirement,
    required int current,
    required String type,
  }) {
    String progressText = '';
    if (!isCompleted) {
      switch (type) {
        case 'ayats':
          progressText = '$current/$requirement ayats';
          break;
        case 'surahs':
          progressText = '$current/$requirement surahs';
          break;
        case 'streak':
          progressText = '$current/$requirement days';
          break;
        case 'time':
          final hours = current ~/ 60;
          final reqHours = requirement ~/ 60;
          progressText = '${hours}h/${reqHours}h';
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smBorder,
          border: Border.all(
            color: isCompleted
                ? AppColors.palm.withOpacity(0.4)
                : AppColors.line,
            width: 1,
          ),
          color: isCompleted
              ? AppColors.palmSoft.withOpacity(0.5)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.palmSoft
                    : AppColors.line.withOpacity(0.4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isCompleted)
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
                    ),
                  Icon(
                    icon,
                    color: isCompleted ? AppColors.palm : AppColors.inkSoft,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCompleted ? AppColors.ink : AppColors.inkSoft,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.palm,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Unlocked',
                            style: TextStyle(
                              color: AppColors.parchment,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                  ),
                  if (!isCompleted && progressText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      progressText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.palm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isCompleted ? AppColors.palm : AppColors.inkSoft,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
