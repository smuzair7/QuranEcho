import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorage {
  // Keys for storing different types of data
  static const String _userStatsKey = 'user_stats';
  static const String _pendingUpdatesKey = 'pending_updates';
  
  // Save user stats to local storage
  static Future<void> saveUserStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStatsKey, json.encode(stats));
    } catch (e) {
      print('Error saving user stats: $e');
    }
  }
  
  // Load user stats from local storage
  static Future<Map<String, dynamic>?> loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsStr = prefs.getString(_userStatsKey);
      
      if (statsStr != null) {
        return json.decode(statsStr) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading user stats: $e');
    }
    return null;
  }
  
  // Add a pending update to queue (for syncing later)
  static Future<void> addPendingUpdate(String endpoint, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> pendingUpdates = [];
      
      final updatesStr = prefs.getString(_pendingUpdatesKey);
      if (updatesStr != null) {
        final List<dynamic> decoded = json.decode(updatesStr);
        pendingUpdates = decoded.cast<Map<String, dynamic>>();
      }
      
      pendingUpdates.add({
        'endpoint': endpoint,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      await prefs.setString(_pendingUpdatesKey, json.encode(pendingUpdates));
    } catch (e) {
      print('Error adding pending update: $e');
    }
  }
  
  // Get all pending updates
  static Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesStr = prefs.getString(_pendingUpdatesKey);
      
      if (updatesStr != null) {
        final List<dynamic> decoded = json.decode(updatesStr);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting pending updates: $e');
    }
    return [];
  }
  
  // Remove a pending update by index
  static Future<void> removePendingUpdate(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesStr = prefs.getString(_pendingUpdatesKey);
      
      if (updatesStr != null) {
        final List<dynamic> decoded = json.decode(updatesStr);
        List<Map<String, dynamic>> pendingUpdates = decoded.cast<Map<String, dynamic>>();
        
        if (index >= 0 && index < pendingUpdates.length) {
          pendingUpdates.removeAt(index);
          await prefs.setString(_pendingUpdatesKey, json.encode(pendingUpdates));
        }
      }
    } catch (e) {
      print('Error removing pending update: $e');
    }
  }
  
  // Clear all pending updates
  static Future<void> clearPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingUpdatesKey);
    } catch (e) {
      print('Error clearing pending updates: $e');
    }
  }
}
