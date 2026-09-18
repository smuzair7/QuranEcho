import 'package:flutter/material.dart';
import 'package:QuranEcho/pages/recite_page.dart';
import '../theme/app_theme.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(title: const Text('Lehja Learning')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.palmSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.record_voice_over,
                    size: 36,
                    color: AppColors.palm,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Learn Quranic recitation style',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select a Qari (reciter) and surah to learn their recitation style',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Reciter dropdown
              DropdownButtonFormField<String>(
                value: _selectedReciter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reciter',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                hint: const Text('Choose a reciter'),
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

              const SizedBox(height: AppSpacing.md),

              // Surah dropdown
              DropdownButtonFormField<String>(
                value: _selectedSurah,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Surah',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                hint: const Text('Choose a surah'),
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

              const Spacer(),

              ElevatedButton.icon(
                onPressed: (_selectedReciter != null && _selectedSurah != null)
                    ? _proceedToRecitation
                    : null,
                icon: const Icon(Icons.headphones),
                label: const Text('Start learning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
