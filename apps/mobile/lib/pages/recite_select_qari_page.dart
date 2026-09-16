import 'package:flutter/material.dart';
import 'package:QuranEcho/pages/recite_page.dart';

class ReciteSelectQariPage extends StatefulWidget {
  const ReciteSelectQariPage({super.key});

  @override
  State<ReciteSelectQariPage> createState() => _ReciteSelectQariPageState();
}

class _ReciteSelectQariPageState extends State<ReciteSelectQariPage> {
  String? _selectedReciter;
  String? _selectedSurah;

  final List<String> _reciters = [
    'Sheikh Abdul Rahman Al-Sudais',
    'Sheikh Mishary Rashid Alafasy',
    'Sheikh Abdul Basit'
  ];

  final List<String> _surahs = [
    'Al-Fatihah',
    'Al-Baqarah',
    'Ali-Imran',
    'An-Nisa',
    'Al-Maidah',
    'Al-Anam',
    'Al-Araf',
    'Al-Anfal'
  ];

  void _proceedToRecitation() {
    if (_selectedReciter != null && _selectedSurah != null) {
      // Map surah name to number and information
      final Map<String, dynamic> surahInfo = {
        'surahNumber': _surahs.indexOf(_selectedSurah!) + 1,
        'surahName': _selectedSurah,
        'arabicName': '', // Add Arabic name if available
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecitePage(
            selectedSurah: _selectedSurah,
            selectedReciter: _selectedReciter,
            surahInfo: surahInfo,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lehja Learning'),
        backgroundColor: const Color(0xFF00A896), // Updated to match Hifz page
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Add dark gradient background to match other pages
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black87,
              const Color(0xFF121212), // Very dark gray
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.record_voice_over,
              size: 70,
              color:
                  const Color(0xFF00A896), // Updated to match Hifz page color
            ),
            const SizedBox(height: 20),
            const Text(
              'Learn Quranic Recitation Style',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Updated for dark theme
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a Qari (reciter) and Surah to learn their recitation style',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70, // Updated for dark theme
              ),
            ),
            const SizedBox(height: 40),

            // Reciter dropdown
            const Text(
              'Select Reciter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white, // Updated for dark theme
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                    0.9), // White background for better readability
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00A896), // Updated border color
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Choose a reciter',
                      style: TextStyle(color: Colors.black87)),
                  value: _selectedReciter,
                  dropdownColor:
                      Colors.white, // Ensure dropdown menu has white background
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16), // Text color for selected item
                  items: _reciters.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedReciter = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Surah dropdown
            const Text(
              'Select Surah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white, // Updated for dark theme
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                    0.9), // White background for better readability
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00A896), // Updated border color
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Choose a surah',
                      style: TextStyle(color: Colors.black87)),
                  value: _selectedSurah,
                  dropdownColor:
                      Colors.white, // Ensure dropdown menu has white background
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16), // Text color for selected item
                  items: _surahs.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSurah = newValue;
                    });
                  },
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: (_selectedReciter != null && _selectedSurah != null)
                  ? _proceedToRecitation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF00A896), // Updated to match Hifz page
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors
                    .grey.shade700, // Darker disabled color for dark theme
              ),
              icon: const Icon(Icons.headphones),
              label: const Text(
                'Start Learning',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
