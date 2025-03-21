import 'dart:convert';
import 'package:http/http.dart' as http;

class UserStatsService {
  // Use the same base URL as auth service
  static const String _baseUrl = 'http://192.168.18.37:3000';
  
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
  
  // Update user stats
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
}