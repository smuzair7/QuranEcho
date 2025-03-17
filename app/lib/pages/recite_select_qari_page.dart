import 'package:flutter/material.dart';
import 'package:quran_echo/pages/recite_page.dart';

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
    'Sheikh Muhammad Siddiq Al-Minshawi',
    'Sheikh Abdul Basit Abdul Samad'
  ];

  final List<String> _surahs = [
    'Al-Fatihah', 'Al-Baqarah', 'Ali-Imran', 'An-Nisa', 
    'Al-Maidah', 'Al-Anam', 'Al-Araf', 'Al-Anfal'
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
        backgroundColor: const Color(0xFF05668D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.record_voice_over,
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Learn Quranic Recitation Style',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a Qari (reciter) and Surah to learn their recitation style',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),
            
            // Reciter dropdown
            Text(
              'Select Reciter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF05668D).withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Choose a reciter'),
                  value: _selectedReciter,
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
            Text(
              'Select Surah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF05668D).withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Choose a surah'),
                  value: _selectedSurah,
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
                backgroundColor: const Color(0xFF05668D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
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