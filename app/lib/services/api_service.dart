import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Default server URL (should be configured for both emulator and physical devices)
  // 10.0.2.2 is the special IP for Android emulator to access host machine's localhost
  static const String _defaultEmulatorBaseUrl = 'http://10.0.2.2:3000';
  static const String _defaultPhysicalDeviceBaseUrl = 'http://192.168.100.113:3000'; // Update this to match your backend IP
  
  // We'll use this to cache server URLs we've successfully connected to
  static String? _cachedBaseUrl;
  static bool _isInitialized = false;

  // Use a global client for connection pooling
  static final http.Client _client = http.Client();
  
  // Timeout durations
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _requestTimeout = Duration(seconds: 15);
  
  // Initialize with fallback URLs to try
  static final List<String> _fallbackUrls = [
    _defaultEmulatorBaseUrl,
    _defaultPhysicalDeviceBaseUrl,
    'http://localhost:3000',
  ];
  
  // Method to initialize and find working server
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // First check if we have a cached URL that worked before
    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString('api_base_url');
    
    if (_cachedBaseUrl != null) {
      // Try the cached URL first
      if (await _testConnection(_cachedBaseUrl!)) {
        _isInitialized = true;
        return true;
      }
    }
    
    // Try each fallback URL until one works
    for (final url in _fallbackUrls) {
      if (await _testConnection(url)) {
        _cachedBaseUrl = url;
        // Cache the working URL
        await prefs.setString('api_base_url', url);
        _isInitialized = true;
        return true;
      }
    }
    
    // If we get here, none of the URLs worked
    _isInitialized = false;
    return false;
  }
  
  // Test if we can connect to a specific URL
  static Future<bool> _testConnection(String baseUrl) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/test'))
          .timeout(_connectionTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed for $baseUrl: $e');
      return false;
    }
  }

  // Generic GET request with error handling
  static Future<Map<String, dynamic>> get(String endpoint) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Could not connect to server. Please check your network connection.');
      }
    }
    
    try {
      final response = await _client
          .get(Uri.parse('${_cachedBaseUrl!}/$endpoint'))
          .timeout(_requestTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('Request failed with status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket exception for GET $endpoint: $e');
      throw Exception('Server connection failed. Please check your network settings.');
    } on TimeoutException catch (e) {
      print('Timeout for GET $endpoint: $e');
      throw Exception('Request timed out. Please try again later.');
    } catch (e) {
      print('Error for GET $endpoint: $e');
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // Generic POST request with error handling
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Could not connect to server. Please check your network connection.');
      }
    }
    
    try {
      final response = await _client
          .post(
            Uri.parse('${_cachedBaseUrl!}/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(_requestTimeout);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw HttpException('Request failed with status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket exception for POST $endpoint: $e');
      throw Exception('Server connection failed. Please check your network settings.');
    } on TimeoutException catch (e) {
      print('Timeout for POST $endpoint: $e');
      throw Exception('Request timed out. Please try again later.');
    } catch (e) {
      print('Error for POST $endpoint: $e');
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // Generic PUT request with error handling
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Could not connect to server. Please check your network connection.');
      }
    }
    
    try {
      final response = await _client
          .put(
            Uri.parse('${_cachedBaseUrl!}/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(_requestTimeout);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw HttpException('Request failed with status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket exception for PUT $endpoint: $e');
      throw Exception('Server connection failed. Please check your network settings.');
    } on TimeoutException catch (e) {
      print('Timeout for PUT $endpoint: $e');
      throw Exception('Request timed out. Please try again later.');
    } catch (e) {
      print('Error for PUT $endpoint: $e');
      throw Exception('An error occurred: ${e.toString()}');
    }
  }
}
