import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Updated to be consistent with other services - use your actual server IP
  static const String _baseUrl = 'http://192.168.100.142:3000';
  
  // Login function
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Attempting login for user: $username');
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      print('Login response status: ${response.statusCode}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('Login successful. User ID: ${data['user']['_id']}');
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('Login failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
  
  // Register function
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registerUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
  
  // Get user stats for dashboard
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user-stats/$userId'),
        headers: {'Content-Type': 'application/json'},
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
          'message': data['message'] ?? 'Failed to load user stats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: ${e.toString()}',
      };
    }
  }
  
  // Update daily goal
  Future<Map<String, dynamic>> updateDailyGoal(String userId, int dailyGoal) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/daily-goal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dailyGoal': dailyGoal,
        }),
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
          'message': data['message'] ?? 'Failed to update daily goal',
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
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/$userId/weekly-progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dayIndex': dayIndex,
          'value': value,
        }),
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