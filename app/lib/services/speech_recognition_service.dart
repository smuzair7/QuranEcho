import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SpeechRecognitionService {
  // Update with the correct server address
  // When using Android emulator, use your laptop IP address that's running the server
  static const String _baseUrl = 'http://192.168.18.37:5000'; // Adjust this to match your server IP
  
  static Future<String> transcribeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }
      
      final bytes = await file.readAsBytes();
      
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/transcribe_local'));
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'audio.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        
        if (jsonResponse is Map && jsonResponse.containsKey('text')) {
          return jsonResponse['text'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error transcribing audio: $e');
      throw Exception('Transcription error: $e');
    }
  }
  
  // Function to check if server is online
  static Future<bool> isServerOnline() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Server health check failed: $e');
      return false;
    }
  }
}
