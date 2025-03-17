import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReadQuranPage extends StatefulWidget {
  final Map<String, dynamic> surahInfo;

  const ReadQuranPage({super.key, required this.surahInfo});

  @override
  State<ReadQuranPage> createState() => _ReadQuranPageState();
}

class _ReadQuranPageState extends State<ReadQuranPage> {
  List<Map<String, dynamic>> ayahs = [];
  bool isLoading = true;
  String errorMessage = '';

  // Helper method to convert western numerals to Arabic numerals
  String toArabicNumerals(int number) {
    const List<String> arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString()
      .split('')
      .map((digit) => arabicNumerals[int.parse(digit)])
      .join();
  }

  @override
  void initState() {
    super.initState();
    _loadSurahContent();
  }

  Future<void> _loadSurahContent() async {
    try {
      debugPrint('Attempting to load quran.json');
      final String jsonData = await rootBundle.loadString('assets/data/quran.json');
      debugPrint('JSON data loaded, length: ${jsonData.length}');
      
      final Map<String, dynamic> quranData = json.decode(jsonData);
      debugPrint('JSON data parsed successfully, contains ${quranData.length} entries');
      
      final int surahNumber = widget.surahInfo['surahNumber'];
      
      // Get the selected surah data
      final Map<String, dynamic>? surahData = quranData[surahNumber.toString()];
      
      if (surahData == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Surah data not found';
        });
        return;
      }
      
      // Parse ayah data
      final List<Map<String, dynamic>> parsedAyahs = [];
      surahData.forEach((ayahNumber, ayahData) {
        parsedAyahs.add({
          'surahNumber': surahNumber,
          'ayahNumber': int.parse(ayahNumber),
          'text': ayahData['displayText'] ?? ayahData['text'], // Use displayText for Quran display
          'plainText': ayahData['text'], // Keep plain text for operations like copying
        });
      });
      
      // Sort ayahs by ayah number
      parsedAyahs.sort((a, b) => a['ayahNumber'].compareTo(b['ayahNumber']));
      
      setState(() {
        ayahs = parsedAyahs;
        isLoading = false;
      });
      
      debugPrint('Loaded ${ayahs.length} ayahs for surah $surahNumber from JSON');
      
    } catch (e) {
      debugPrint('Error details: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading surah content: $e';
      });
      debugPrint('Error loading surah content: $e');
      debugPrintStack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.surahInfo['surahName']} (${widget.surahInfo['arabicName']})'),
        backgroundColor: const Color(0xFF00A896),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildSurahContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load surah content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _loadSurahContent();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahContent() {
    // Check if we should show Bismillah (not shown for Surah 1 or Surah 9)
    final int surahNumber = widget.surahInfo['surahNumber'];
    final shouldShowBismillah = surahNumber != 1 && surahNumber != 9;

    // Add this debug statement
    debugPrint('Surah number: $surahNumber, Should show bismillah: $shouldShowBismillah');
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00A896).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Surah Header
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00A896).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00A896).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.surahInfo['arabicName'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Scheherazade',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Surah ${widget.surahInfo['surahNumber']}: ${widget.surahInfo['surahName']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${widget.surahInfo['ayahCount']} Ayahs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Continuous surah text container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bismillah header - only show for surahs other than Fatiha and Tawbah
                  if (shouldShowBismillah)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontFamily: 'Scheherazade',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A896),
                          height: 1.8,
                        ),
                      ),
                    ),
                  
                  RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Scheherazade',
                        color: Colors.black,
                        height: 1.8,
                      ),
                      children: _buildAyahTextSpans(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions row at bottom
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_outline),
                    tooltip: 'Bookmark this surah',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.surahInfo['surahName']} bookmarked')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    tooltip: 'Copy surah text',
                    onPressed: () {
                      final allText = ayahs.map((ayah) => ayah['plainText'] ?? ayah['text']).join(' ');
                      Clipboard.setData(ClipboardData(text: allText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Surah text copied to clipboard')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share surah',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing functionality coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<InlineSpan> _buildAyahTextSpans() {
    List<InlineSpan> spans = [];
    
    for (int i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      
      // Add ayah number in a circle with Arabic numerals
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF00A896),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              toArabicNumerals(ayah['ayahNumber']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Scheherazade',
              ),
            ),
          ),
        ),
      );
      
      // Add the ayah text
      spans.add(TextSpan(text: '${ayah['text']} '));
    }
    
    return spans;
  }
}