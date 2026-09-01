import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get huggingFaceApiToken => dotenv.env['HUGGING_FACE_API_TOKEN'] ?? '';
  static String get tarteelApiUrl => dotenv.env['TARTEEL_API_URL'] ?? '';
  
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      return;
    }
  }
  
  static bool get isConfigured => 
    huggingFaceApiToken.isNotEmpty && tarteelApiUrl.isNotEmpty;
}
