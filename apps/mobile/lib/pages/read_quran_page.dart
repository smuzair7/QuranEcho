import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

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
    const List<String> arabicNumerals = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩'
    ];
    return number
        .toString()
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
      final String jsonData =
          await rootBundle.loadString('assets/data/quran.json');
      debugPrint('JSON data loaded, length: ${jsonData.length}');

      final Map<String, dynamic> quranData = json.decode(jsonData);
      debugPrint(
          'JSON data parsed successfully, contains ${quranData.length} entries');

      // Extract the actual surahInfo object if it's nested
      final Map<String, dynamic> actualSurahInfo =
          widget.surahInfo.containsKey('surahInfo')
              ? widget.surahInfo['surahInfo']
              : widget.surahInfo;

      debugPrint('Extracted surahInfo: $actualSurahInfo');

      // Add null check and type conversion for surahNumber
      final dynamic rawSurahNumber = actualSurahInfo['surahNumber'];
      if (rawSurahNumber == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Surah number is missing';
        });
        debugPrint('Error: Surah number is null in actualSurahInfo: $actualSurahInfo');
        return;
      }

      // Convert to int if needed
      final int surahNumber = rawSurahNumber is int
          ? rawSurahNumber
          : int.tryParse(rawSurahNumber.toString()) ?? 0;

      if (surahNumber <= 0 || surahNumber > 114) {
        setState(() {
          isLoading = false;
          errorMessage = 'Invalid surah number: $surahNumber';
        });
        debugPrint('Error: Invalid surah number: $surahNumber');
        return;
      }

      debugPrint('Processing surah number: $surahNumber');

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
          'text': ayahData['displayText'] ??
              ayahData['text'], // Use displayText for Quran display
          'plainText':
              ayahData['text'], // Keep plain text for operations like copying
        });
      });

      // Sort ayahs by ayah number
      parsedAyahs.sort((a, b) => a['ayahNumber'].compareTo(b['ayahNumber']));

      setState(() {
        ayahs = parsedAyahs;
        isLoading = false;
      });

      debugPrint(
          'Loaded ${ayahs.length} ayahs for surah $surahNumber from JSON');
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
    // Extract the actual surahInfo object if it's nested
    final Map<String, dynamic> actualSurahInfo =
        widget.surahInfo.containsKey('surahInfo')
            ? widget.surahInfo['surahInfo']
            : widget.surahInfo;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${actualSurahInfo['surahName']} (${actualSurahInfo['arabicName']})'),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.clay),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load surah content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.md),
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
    // Extract the actual surahInfo object if it's nested
    final Map<String, dynamic> actualSurahInfo =
        widget.surahInfo.containsKey('surahInfo')
            ? widget.surahInfo['surahInfo']
            : widget.surahInfo;

    // Check if we should show Bismillah (not shown for Surah 1 or Surah 9)
    final int surahNumber = actualSurahInfo['surahNumber'];
    final shouldShowBismillah = surahNumber != 1 && surahNumber != 9;

    // Add this debug statement
    debugPrint(
        'Surah number: $surahNumber, Should show bismillah: $shouldShowBismillah');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Surah header
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.palmSoft,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Column(
              children: [
                Text(
                  actualSurahInfo['arabicName'],
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: 'Amiri Quran',
                    color: AppColors.palmDeep,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Surah ${actualSurahInfo['surahNumber']}: ${actualSurahInfo['surahName']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${actualSurahInfo['ayahCount']} ayahs',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),

          // Continuous surah text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bismillah header - only show for surahs other than Fatiha and Tawbah
                  if (shouldShowBismillah)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontFamily: 'Amiri Quran',
                          color: AppColors.palm,
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
                        fontFamily: 'Amiri Quran',
                        color: AppColors.ink,
                        height: 1.9,
                      ),
                      children: _buildAyahTextSpans(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions row at bottom
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_outline),
                  tooltip: 'Bookmark this surah',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${actualSurahInfo['surahName']} bookmarked')),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  tooltip: 'Copy surah text',
                  onPressed: () {
                    final allText = ayahs
                        .map((ayah) => ayah['plainText'] ?? ayah['text'])
                        .join(' ');
                    Clipboard.setData(ClipboardData(text: allText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Surah text copied to clipboard')),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share surah',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sharing functionality coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: const BoxDecoration(
              color: AppColors.palmSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              toArabicNumerals(ayah['ayahNumber']),
              style: const TextStyle(
                color: AppColors.palmDeep,
                fontSize: 10,
                fontFamily: 'Amiri Quran',
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