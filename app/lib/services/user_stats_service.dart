import 'dart:convert';
import 'package:http/http.dart' as http;

class UserStatsService {
  // Use the same base URL as auth service - Updated to match auth_service.dart
  static const String _baseUrl = 'http://192.168.100.142:3000';
  
  // Get user stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Validate user ID
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to getUserStats');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      print('Getting stats for user ID: $userId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user-stats/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Stats response status: ${response.statusCode}');
      // Only print a preview of the response body to avoid flooding logs
      final bodyPreview = response.body.length > 100 
          ? '${response.body.substring(0, 100)}...'
          : response.body;
      print('Stats response body preview: $bodyPreview');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('Error getting stats: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve user stats',
        };
      }
    } catch (e) {
      print('Error in getUserStats: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
  
  // Update daily goal
  Future<Map<String, dynamic>> updateDailyGoal(String userId, int dailyGoal) async {
    try {
      print('Updating goal to $dailyGoal for user ID: $userId');
      
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateDailyGoal');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/daily-goal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dailyGoal': dailyGoal}),
      );
      
      print('Update goal response status: ${response.statusCode}');
      print('Update goal response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update daily goal',
        };
      }
    } catch (e) {
      print('Error in updateDailyGoal: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
  
  // Update user stats - Generic method for updating stats
  Future<Map<String, dynamic>> updateUserStats(String userId, Map<String, dynamic> stats) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateUserStats');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(stats),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update user stats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
  
  // Update weekly progress
  Future<Map<String, dynamic>> updateWeeklyProgress(String userId, int dayIndex, int value) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateWeeklyProgress');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/weekly-progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dayIndex': dayIndex, 'value': value}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update weekly progress',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Add time spent method to match your backend API
  Future<Map<String, dynamic>> addTimeSpent(String userId, int timeMinutes) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to addTimeSpent');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user-stats/$userId/add-time'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'timeMinutes': timeMinutes}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add time',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Add memorized ayah - NEW: Add specific ayah instead of total count
  Future<Map<String, dynamic>> addMemorizedAyah(String userId, int surahNumber, int ayahNumber) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to addMemorizedAyah');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/memorized-ayats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'surahNumber': surahNumber, 'ayahNumber': ayahNumber}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add memorized ayah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Update memorized ayats (backwards compatibility)
  Future<Map<String, dynamic>> updateMemorizedAyats(String userId, int count) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateMemorizedAyats');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user-stats/$userId/memorized-ayats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'count': count}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update memorized ayats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Add memorized surah - NEW: Add specific surah instead of total count
  Future<Map<String, dynamic>> addMemorizedSurah(String userId, int surahNumber) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to addMemorizedSurah');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/memorized-surahs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'surahNumber': surahNumber}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add memorized surah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Update memorized surahs (backwards compatibility)
  Future<Map<String, dynamic>> updateMemorizedSurahs(String userId, int count) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateMemorizedSurahs');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user-stats/$userId/memorized-surahs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'count': count}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update memorized surahs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Update surah progress
  Future<Map<String, dynamic>> updateSurahProgress(String userId, int surahNumber, int progress) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateSurahProgress');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/surah-progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'surahNumber': surahNumber, 'progress': progress}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update surah progress',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }

  // Update streak
  Future<Map<String, dynamic>> updateStreak(String userId, int streakDays) async {
    try {
      if (userId.isEmpty) {
        print('Error: Empty user ID passed to updateStreak');
        return {
          'success': false,
          'message': 'User ID is missing or invalid',
        };
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/streak'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'streakDays': streakDays}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update streak',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
}
