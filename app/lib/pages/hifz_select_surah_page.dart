import 'package:flutter/material.dart';

class HifzSelectSurahPage extends StatefulWidget {
  const HifzSelectSurahPage({super.key});

  @override
  State<HifzSelectSurahPage> createState() => _HifzSelectSurahPageState();
}

class _HifzSelectSurahPageState extends State<HifzSelectSurahPage> {
  // Complete list of all 114 surahs with their names and number of ayahs
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
    {'number': 11, 'name': 'Hud', 'arabicName': 'هود', 'ayahs': 123},
    {'number': 12, 'name': 'Yusuf', 'arabicName': 'يوسف', 'ayahs': 111},
    {'number': 13, 'name': 'Ar-Ra\'d', 'arabicName': 'الرعد', 'ayahs': 43},
    {'number': 14, 'name': 'Ibrahim', 'arabicName': 'إبراهيم', 'ayahs': 52},
    {'number': 15, 'name': 'Al-Hijr', 'arabicName': 'الحجر', 'ayahs': 99},
    {'number': 16, 'name': 'An-Nahl', 'arabicName': 'النحل', 'ayahs': 128},
    {'number': 17, 'name': 'Al-Isra', 'arabicName': 'الإسراء', 'ayahs': 111},
    {'number': 18, 'name': 'Al-Kahf', 'arabicName': 'الكهف', 'ayahs': 110},
    {'number': 19, 'name': 'Maryam', 'arabicName': 'مريم', 'ayahs': 98},
    {'number': 20, 'name': 'Ta-Ha', 'arabicName': 'طه', 'ayahs': 135},
    {'number': 21, 'name': 'Al-Anbiya', 'arabicName': 'الأنبياء', 'ayahs': 112},
    {'number': 22, 'name': 'Al-Hajj', 'arabicName': 'الحج', 'ayahs': 78},
    {'number': 23, 'name': 'Al-Mu\'minun', 'arabicName': 'المؤمنون', 'ayahs': 118},
    {'number': 24, 'name': 'An-Nur', 'arabicName': 'النور', 'ayahs': 64},
    {'number': 25, 'name': 'Al-Furqan', 'arabicName': 'الفرقان', 'ayahs': 77},
    {'number': 26, 'name': 'Ash-Shu\'ara', 'arabicName': 'الشعراء', 'ayahs': 227},
    {'number': 27, 'name': 'An-Naml', 'arabicName': 'النمل', 'ayahs': 93},
    {'number': 28, 'name': 'Al-Qasas', 'arabicName': 'القصص', 'ayahs': 88},
    {'number': 29, 'name': 'Al-Ankabut', 'arabicName': 'العنكبوت', 'ayahs': 69},
    {'number': 30, 'name': 'Ar-Rum', 'arabicName': 'الروم', 'ayahs': 60},
    {'number': 31, 'name': 'Luqman', 'arabicName': 'لقمان', 'ayahs': 34},
    {'number': 32, 'name': 'As-Sajdah', 'arabicName': 'السجدة', 'ayahs': 30},
    {'number': 33, 'name': 'Al-Ahzab', 'arabicName': 'الأحزاب', 'ayahs': 73},
    {'number': 34, 'name': 'Saba', 'arabicName': 'سبأ', 'ayahs': 54},
    {'number': 35, 'name': 'Fatir', 'arabicName': 'فاطر', 'ayahs': 45},
    {'number': 36, 'name': 'Ya-Sin', 'arabicName': 'يس', 'ayahs': 83},
    {'number': 37, 'name': 'As-Saffat', 'arabicName': 'الصافات', 'ayahs': 182},
    {'number': 38, 'name': 'Sad', 'arabicName': 'ص', 'ayahs': 88},
    {'number': 39, 'name': 'Az-Zumar', 'arabicName': 'الزمر', 'ayahs': 75},
    {'number': 40, 'name': 'Ghafir', 'arabicName': 'غافر', 'ayahs': 85},
    {'number': 41, 'name': 'Fussilat', 'arabicName': 'فصلت', 'ayahs': 54},
    {'number': 42, 'name': 'Ash-Shura', 'arabicName': 'الشورى', 'ayahs': 53},
    {'number': 43, 'name': 'Az-Zukhruf', 'arabicName': 'الزخرف', 'ayahs': 89},
    {'number': 44, 'name': 'Ad-Dukhan', 'arabicName': 'الدخان', 'ayahs': 59},
    {'number': 45, 'name': 'Al-Jathiyah', 'arabicName': 'الجاثية', 'ayahs': 37},
    {'number': 46, 'name': 'Al-Ahqaf', 'arabicName': 'الأحقاف', 'ayahs': 35},
    {'number': 47, 'name': 'Muhammad', 'arabicName': 'محمد', 'ayahs': 38},
    {'number': 48, 'name': 'Al-Fath', 'arabicName': 'الفتح', 'ayahs': 29},
    {'number': 49, 'name': 'Al-Hujurat', 'arabicName': 'الحجرات', 'ayahs': 18},
    {'number': 50, 'name': 'Qaf', 'arabicName': 'ق', 'ayahs': 45},
    {'number': 51, 'name': 'Adh-Dhariyat', 'arabicName': 'الذاريات', 'ayahs': 60},
    {'number': 52, 'name': 'At-Tur', 'arabicName': 'الطور', 'ayahs': 49},
    {'number': 53, 'name': 'An-Najm', 'arabicName': 'النجم', 'ayahs': 62},
    {'number': 54, 'name': 'Al-Qamar', 'arabicName': 'القمر', 'ayahs': 55},
    {'number': 55, 'name': 'Ar-Rahman', 'arabicName': 'الرحمن', 'ayahs': 78},
    {'number': 56, 'name': 'Al-Waqi\'ah', 'arabicName': 'الواقعة', 'ayahs': 96},
    {'number': 57, 'name': 'Al-Hadid', 'arabicName': 'الحديد', 'ayahs': 29},
    {'number': 58, 'name': 'Al-Mujadilah', 'arabicName': 'المجادلة', 'ayahs': 22},
    {'number': 59, 'name': 'Al-Hashr', 'arabicName': 'الحشر', 'ayahs': 24},
    {'number': 60, 'name': 'Al-Mumtahanah', 'arabicName': 'الممتحنة', 'ayahs': 13},
    {'number': 61, 'name': 'As-Saff', 'arabicName': 'الصف', 'ayahs': 14},
    {'number': 62, 'name': 'Al-Jumu\'ah', 'arabicName': 'الجمعة', 'ayahs': 11},
    {'number': 63, 'name': 'Al-Munafiqun', 'arabicName': 'المنافقون', 'ayahs': 11},
    {'number': 64, 'name': 'At-Taghabun', 'arabicName': 'التغابن', 'ayahs': 18},
    {'number': 65, 'name': 'At-Talaq', 'arabicName': 'الطلاق', 'ayahs': 12},
    {'number': 66, 'name': 'At-Tahrim', 'arabicName': 'التحريم', 'ayahs': 12},
    {'number': 67, 'name': 'Al-Mulk', 'arabicName': 'الملك', 'ayahs': 30},
    {'number': 68, 'name': 'Al-Qalam', 'arabicName': 'القلم', 'ayahs': 52},
    {'number': 69, 'name': 'Al-Haqqah', 'arabicName': 'الحاقة', 'ayahs': 52},
    {'number': 70, 'name': 'Al-Ma\'arij', 'arabicName': 'المعارج', 'ayahs': 44},
    {'number': 71, 'name': 'Nuh', 'arabicName': 'نوح', 'ayahs': 28},
    {'number': 72, 'name': 'Al-Jinn', 'arabicName': 'الجن', 'ayahs': 28},
    {'number': 73, 'name': 'Al-Muzzammil', 'arabicName': 'المزمل', 'ayahs': 20},
    {'number': 74, 'name': 'Al-Muddaththir', 'arabicName': 'المدثر', 'ayahs': 56},
    {'number': 75, 'name': 'Al-Qiyamah', 'arabicName': 'القيامة', 'ayahs': 40},
    {'number': 76, 'name': 'Al-Insan', 'arabicName': 'الإنسان', 'ayahs': 31},
    {'number': 77, 'name': 'Al-Mursalat', 'arabicName': 'المرسلات', 'ayahs': 50},
    {'number': 78, 'name': 'An-Naba', 'arabicName': 'النبأ', 'ayahs': 40},
    {'number': 79, 'name': 'An-Nazi\'at', 'arabicName': 'النازعات', 'ayahs': 46},
    {'number': 80, 'name': 'Abasa', 'arabicName': 'عبس', 'ayahs': 42},
    {'number': 81, 'name': 'At-Takwir', 'arabicName': 'التكوير', 'ayahs': 29},
    {'number': 82, 'name': 'Al-Infitar', 'arabicName': 'الانفطار', 'ayahs': 19},
    {'number': 83, 'name': 'Al-Mutaffifin', 'arabicName': 'المطففين', 'ayahs': 36},
    {'number': 84, 'name': 'Al-Inshiqaq', 'arabicName': 'الانشقاق', 'ayahs': 25},
    {'number': 85, 'name': 'Al-Buruj', 'arabicName': 'البروج', 'ayahs': 22},
    {'number': 86, 'name': 'At-Tariq', 'arabicName': 'الطارق', 'ayahs': 17},
    {'number': 87, 'name': 'Al-A\'la', 'arabicName': 'الأعلى', 'ayahs': 19},
    {'number': 88, 'name': 'Al-Ghashiyah', 'arabicName': 'الغاشية', 'ayahs': 26},
    {'number': 89, 'name': 'Al-Fajr', 'arabicName': 'الفجر', 'ayahs': 30},
    {'number': 90, 'name': 'Al-Balad', 'arabicName': 'البلد', 'ayahs': 20},
    {'number': 91, 'name': 'Ash-Shams', 'arabicName': 'الشمس', 'ayahs': 15},
    {'number': 92, 'name': 'Al-Layl', 'arabicName': 'الليل', 'ayahs': 21},
    {'number': 93, 'name': 'Ad-Duha', 'arabicName': 'الضحى', 'ayahs': 11},
    {'number': 94, 'name': 'Ash-Sharh', 'arabicName': 'الشرح', 'ayahs': 8},
    {'number': 95, 'name': 'At-Tin', 'arabicName': 'التين', 'ayahs': 8},
    {'number': 96, 'name': 'Al-Alaq', 'arabicName': 'العلق', 'ayahs': 19},
    {'number': 97, 'name': 'Al-Qadr', 'arabicName': 'القدر', 'ayahs': 5},
    {'number': 98, 'name': 'Al-Bayyinah', 'arabicName': 'البينة', 'ayahs': 8},
    {'number': 99, 'name': 'Az-Zalzalah', 'arabicName': 'الزلزلة', 'ayahs': 8},
    {'number': 100, 'name': 'Al-Adiyat', 'arabicName': 'العاديات', 'ayahs': 11},
    {'number': 101, 'name': 'Al-Qari\'ah', 'arabicName': 'القارعة', 'ayahs': 11},
    {'number': 102, 'name': 'At-Takathur', 'arabicName': 'التكاثر', 'ayahs': 8},
    {'number': 103, 'name': 'Al-Asr', 'arabicName': 'العصر', 'ayahs': 3},
    {'number': 104, 'name': 'Al-Humazah', 'arabicName': 'الهمزة', 'ayahs': 9},
    {'number': 105, 'name': 'Al-Fil', 'arabicName': 'الفيل', 'ayahs': 5},
    {'number': 106, 'name': 'Quraysh', 'arabicName': 'قريش', 'ayahs': 4},
    {'number': 107, 'name': 'Al-Ma\'un', 'arabicName': 'الماعون', 'ayahs': 7},
    {'number': 108, 'name': 'Al-Kawthar', 'arabicName': 'الكوثر', 'ayahs': 3},
    {'number': 109, 'name': 'Al-Kafirun', 'arabicName': 'الكافرون', 'ayahs': 6},
    {'number': 110, 'name': 'An-Nasr', 'arabicName': 'النصر', 'ayahs': 3},
    {'number': 111, 'name': 'Al-Masad', 'arabicName': 'المسد', 'ayahs': 5},
    {'number': 112, 'name': 'Al-Ikhlas', 'arabicName': 'الإخلاص', 'ayahs': 4},
    {'number': 113, 'name': 'Al-Falaq', 'arabicName': 'الفلق', 'ayahs': 5},
    {'number': 114, 'name': 'An-Nas', 'arabicName': 'الناس', 'ayahs': 6},
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