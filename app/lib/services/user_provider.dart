import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  String? _username;
  String? _userId;
  Map<String, dynamic>? _userStats;

  String? get username => _username;
  String? get userId => _userId;
  Map<String, dynamic>? get userStats => _userStats;
  
  bool get isLoggedIn => _username != null && _userId != null;

  UserProvider() {
    // Load saved user session on initialization
    _loadUserSession();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get stored values
      final storedUsername = prefs.getString('username');
      final storedUserId = prefs.getString('userId');
      final storedStatsString = prefs.getString('userStats');
      
      print('Loading saved session - Username: $storedUsername, UserID: $storedUserId');
      
      // Parse stored stats if available
      Map<String, dynamic>? storedStats;
      if (storedStatsString != null) {
        try {
          storedStats = jsonDecode(storedStatsString) as Map<String, dynamic>;
        } catch (e) {
          print('Error parsing stored stats: $e');
        }
      }
      
      // Update state if values exist
      if (storedUsername != null && storedUserId != null) {
        _username = storedUsername;
        _userId = storedUserId;
        _userStats = storedStats;
        notifyListeners();
        print('Session restored - Username: $_username, UserID: $_userId');
      }
    } catch (e) {
      print('Error loading user session: $e');
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_username != null && _userId != null) {
        await prefs.setString('username', _username!);
        await prefs.setString('userId', _userId!);
        
        if (_userStats != null) {
          await prefs.setString('userStats', jsonEncode(_userStats));
        }
        
        print('Session saved - Username: $_username, UserID: $_userId');
      }
    } catch (e) {
      print('Error saving user session: $e');
    }
  }

  Future<void> login(String username, [String? userId, Map<String, dynamic>? stats]) async {
    print('Login called - Username: $username, UserID: $userId');
    
    _username = username;
    // Store the MongoDB ObjectId from login response
    _userId = userId;
    _userStats = stats;
    
    // Save to persistent storage
    await _saveUserSession();
    notifyListeners();
  }

  Future<void> logout() async {
    _username = null;
    _userId = null;
    _userStats = null;
    
    // Clear from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('userId');
      await prefs.remove('userStats');
      print('User session cleared from storage');
    } catch (e) {
      print('Error clearing user session: $e');
    }
    
    notifyListeners();
  }

  Future<void> updateUserStats(Map<String, dynamic> stats) async {
    _userStats = stats;
    
    // Update in persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userStats', jsonEncode(_userStats));
      print('User stats updated in storage');
    } catch (e) {
      print('Error updating user stats in storage: $e');
    }
    
    notifyListeners();
  }
}
