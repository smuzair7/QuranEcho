import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../services/user_stats_service.dart';
import 'login_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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
          title: const Text('Set Daily Goal'),
          content: TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ayats per day',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => _updateDailyGoal(context),
              child: const Text('SAVE'),
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
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // If user is not logged in, show login prompt
    if (!userProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: const Color(0xFF00A896),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please log in to view your dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: const Color(0xFF00A896),
          foregroundColor: Colors.white,
        ),
        body: Container(
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
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00A896),
            ),
          ),
        ),
      );
    }
    
    // Show error message if there was an error loading data
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: const Color(0xFF00A896),
          foregroundColor: Colors.white,
        ),
        body: Container(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  'Failed to load dashboard data',
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
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loadUserStats,
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
    
    // User is logged in, show dashboard
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF00A896),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
      body: Container(
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
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadUserStats();
            },
            color: const Color(0xFF00A896),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User profile card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: const Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              userProvider.username?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProvider.username ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Member since: January 2023',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.local_fire_department, 
                                         color: Colors.orange[600], size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_streakDays day streak',
                                      style: TextStyle(
                                        color: Colors.orange[600],
                                        fontWeight: FontWeight.bold,
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
                  
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        title: 'Memorized Ayats',
                        value: _memorizedAyats.toString(),
                        icon: Icons.auto_stories,
                        color: const Color(0xFF00A896),
                      ),
                      _buildStatCard(
                        title: 'Completed Surahs',
                        value: _memorizedSurahs.toString(),
                        icon: Icons.bookmark,
                        color: const Color(0xFF05668D),
                      ),
                      _buildStatCard(
                        title: 'Time Spent',
                        value: _formatTimeSpent(_timeSpentMinutes),
                        icon: Icons.timer,
                        color: const Color(0xFF028090),
                      ),
                      _buildGoalCard(
                        title: 'Daily Goal',
                        value: '$_dailyGoal ayats/day',
                        icon: Icons.flag,
                        color: const Color(0xFF1F8A70),
                        onTap: _showGoalDialog,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Weekly Progress Chart
                  const Text(
                    'Weekly Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ayats Memorized: Last 7 Days',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                          style: TextStyle(
                                            color: Colors.grey[400],
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
                                          style: TextStyle(
                                            color: Colors.grey[400],
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
                                  return FlLine(
                                    color: Colors.grey[800],
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
                                          ? const Color(0xFF00A896)
                                          : Colors.redAccent,
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
                  
                  const SizedBox(height: 24),
                  
                  // Achievement Section
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildAchievementItem(
                          icon: Icons.star,
                          title: 'First Step',
                          description: 'Memorized your first ayat',
                          isCompleted: true,
                        ),
                        _buildAchievementItem(
                          icon: Icons.book,
                          title: 'Surah Completer',
                          description: 'Memorized an entire surah',
                          isCompleted: true,
                        ),
                        _buildAchievementItem(
                          icon: Icons.local_fire_department,
                          title: 'Week Streak',
                          description: 'Used the app for 7 days in a row',
                          isCompleted: true,
                        ),
                        _buildAchievementItem(
                          icon: Icons.military_tech,
                          title: 'Hifz Master',
                          description: 'Memorize 10 surahs',
                          isCompleted: false,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 30,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
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
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF00A896).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: isCompleted ? const Color(0xFF00A896) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? const Color(0xFF00A896) : Colors.grey,
          ),
        ],
      ),
    );
  }
}
