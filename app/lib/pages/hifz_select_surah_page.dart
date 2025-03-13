import 'package:flutter/material.dart';

class HifzSelectSurahPage extends StatefulWidget {
  const HifzSelectSurahPage({super.key});

  @override
  State<HifzSelectSurahPage> createState() => _HifzSelectSurahPageState();
}

class _HifzSelectSurahPageState extends State<HifzSelectSurahPage> {
  // List of surahs with their names and number of ayahs
  final List<Map<String, dynamic>> _surahs = [
    {'number': 1, 'name': 'Al-Fatihah', 'arabicName': 'الفاتحة', 'ayahs': 7},
    {'number': 2, 'name': 'Al-Baqarah', 'arabicName': 'البقرة', 'ayahs': 286},
    {'number': 3, 'name': 'Aali Imran', 'arabicName': 'آل عمران', 'ayahs': 200},
    {'number': 4, 'name': 'An-Nisa', 'arabicName': 'النساء', 'ayahs': 176},
    {'number': 5, 'name': 'Al-Ma\'idah', 'arabicName': 'المائدة', 'ayahs': 120},
    {'number': 6, 'name': 'Al-An\'am', 'arabicName': 'الأنعام', 'ayahs': 165},
    {'number': 7, 'name': 'Al-A\'raf', 'arabicName': 'الأعراف', 'ayahs': 206},
    {'number': 8, 'name': 'Al-Anfal', 'arabicName': 'الأنفال', 'ayahs': 75},
    {'number': 9, 'name': 'At-Tawbah', 'arabicName': 'التوبة', 'ayahs': 129},
    {'number': 10, 'name': 'Yunus', 'arabicName': 'يونس', 'ayahs': 109},
    // Add more surahs as needed
  ];

  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = List.from(_surahs);
  }

  void _filterSurahs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSurahs = List.from(_surahs);
      } else {
        _filteredSurahs = _surahs
            .where((surah) =>
                surah['name'].toLowerCase().contains(query.toLowerCase()) ||
                surah['arabicName'].contains(query) ||
                surah['number'].toString().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Surah'),
        backgroundColor: const Color(0xFF00A896),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterSurahs,
              decoration: InputDecoration(
                hintText: 'Search surah...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00A896), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // List of surahs
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSurahs.length,
              itemBuilder: (context, index) {
                final surah = _filteredSurahs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      child: Text(surah['number'].toString()),
                    ),
                    title: Text(
                      surah['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "${surah['ayahs']} Ayahs",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Text(
                      surah['arabicName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Scheherazade',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context, 
                        '/hifz',
                        arguments: {
                          'surahNumber': surah['number'],
                          'surahName': surah['name'],
                          'arabicName': surah['arabicName'],
                          'ayahCount': surah['ayahs'],
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
