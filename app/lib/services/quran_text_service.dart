import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class QuranTextService {
  static final Map<int, Map<int, String>> _quranText = {};
  static bool _isInitialized = false;

  /// Loads the Quranic text from the CSV file
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String rawData =
          await rootBundle.loadString('assets/data/Arabic-Original.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(rawData);

      // Skip header if exists
      int startIndex = csvTable[0][0] is int ||
              csvTable[0][0].toString().contains(RegExp(r'^\d+$'))
          ? 0
          : 1;

      for (int i = startIndex; i < csvTable.length; i++) {
        final row = csvTable[i];
        // Assuming CSV format: surah_no,ayah_no,text
        if (row.length >= 3) {
          int surahNo = int.parse(row[0].toString());
          int ayahNo = int.parse(row[1].toString());
          String text = row[2].toString();

          _quranText[surahNo] ??= {};
          _quranText[surahNo]![ayahNo] = text;
        }
      }

      _isInitialized = true;
    } catch (e) {
      print('Error loading Quran text: $e');
      throw Exception('Failed to load Quran text: $e');
    }
  }

  /// Returns the original ayah text for the given surah and ayah
  static String? getAyah(int surahNo, int ayahNo) {
    if (!_isInitialized) {
      throw Exception(
          'QuranTextService not initialized. Call initialize() first.');
    }

    return _quranText[surahNo]?[ayahNo];
  }

  /// Returns all ayahs for a given surah
  static Map<int, String>? getSurah(int surahNo) {
    if (!_isInitialized) {
      throw Exception(
          'QuranTextService not initialized. Call initialize() first.');
    }

    return _quranText[surahNo];
  }
}
