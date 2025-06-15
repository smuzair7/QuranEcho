import 'dart:convert';
import 'package:http/http.dart' as http;

class SurahProgressService {
  static const String _baseUrl = 'http://192.168.18.37:3000/api';

  // Get user's surah progress from backend
  Future<Map<String, dynamic>> getUserSurahProgress(String userId) async {
    try {
      print('Fetching surah progress for user: $userId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user-stats/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Surah progress response status: ${response.statusCode}');
      print('Surah progress response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if the response has surah progress data
        if (data.containsKey('surahProgress') && data['surahProgress'] != null) {
          // Use actual surah progress from backend
          return {
            'success': true,
            'data': {
              'surahProgress': data['surahProgress'],
            },
          };
        } else {
          // If no surah progress field exists, return empty progress
          // This means the user hasn't started any surahs yet
          return {
            'success': true,
            'data': {
              'surahProgress': {},
            },
          };
        }
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch surah progress',
        };
      }
    } catch (e) {
      print('Error fetching surah progress: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server. Please check your connection.',
      };
    }
  }

  // Update surah progress
  Future<Map<String, dynamic>> updateSurahProgress({
    required String userId,
    required int surahNumber,
    required int memorizedAyats,
  }) async {
    try {
      print('Updating surah progress - User: $userId, Surah: $surahNumber, Ayats: $memorizedAyats');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/user-stats/surah-progress'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'surahNumber': surahNumber,
          'memorizedAyats': memorizedAyats,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Update surah progress response status: ${response.statusCode}');
      print('Update surah progress response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update surah progress',
        };
      }
    } catch (e) {
      print('Error updating surah progress: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }
}

  // Update surah progress (for future implementation)
  Future<Map<String, dynamic>> updateSurahProgress({
    required String userId,
    required int surahNumber,
    required int memorizedAyats,
  }) async {
    try {
      print('Updating surah progress - User: $userId, Surah: $surahNumber, Ayats: $memorizedAyats');
      
      // For now, return success since we don't have the endpoint yet
      return {
        'success': true,
        'message': 'Surah progress updated successfully',
      };
      
      // TODO: Implement actual API call when backend is ready
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl/user-stats/update-surah-progress'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'surahNumber': surahNumber,
          'memorizedAyats': memorizedAyats,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update surah progress',
        };
      }
      */
    } catch (e) {
      print('Error updating surah progress: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }