import 'package:flutter/material.dart';

class MakharijDebugPage extends StatefulWidget {
  const MakharijDebugPage({super.key});

  @override
  State<MakharijDebugPage> createState() => _MakharijDebugPageState();
}

class _MakharijDebugPageState extends State<MakharijDebugPage> {
  // Arabic to English mapping - same as in app.py
  final Map<String, String> arabicToEnglishMap = {
    'ع': 'Aain', // 0
    'ا': 'Alif', // 1
    'ب': 'Ba', // 2
    'د': 'Dal', // 3
    'ض': 'Duad', // 4
    'ف': 'Faa', // 5
    'غ': 'Ghain', // 6
    'ه': 'Haa', // 7
    'ح': 'Hha', // 8
    'ج': 'Jeem', // 9
    'ك': 'Kaif', // 10
    'خ': 'Kha', // 11
    'ل': 'Laam', // 12
    'م': 'Meem', // 13
    'ن': 'Noon', // 14
    'ق': 'Qauf', // 15
    'ر': 'Raa', // 16
    'ث': 'Sa', // 17
    'ص': 'Saud', // 18
    'س': 'Seen', // 19
    'ش': 'Sheen', // 20
    'ت': 'Ta', // 21
    'ط': 'Tua', // 22
    'و': 'Wao', // 23
    'ي': 'Yaa', // 24
    'ز': 'Zaa', // 25
    'ذ': 'Zhal', // 26
    'ظ': 'Zua' // 27
  };

  // The correct ordered list according to app.py
  final List<String> orderedLetters = [
    'ع',
    'ا',
    'ب',
    'د',
    'ض',
    'ف',
    'غ',
    'ه',
    'ح',
    'ج',
    'ك',
    'خ',
    'ل',
    'م',
    'ن',
    'ق',
    'ر',
    'ث',
    'ص',
    'س',
    'ش',
    'ت',
    'ط',
    'و',
    'ي',
    'ز',
    'ذ',
    'ظ'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Makharij Debug"),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Letter Mapping Debugger',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'This screen shows the correct order of Arabic letters according to the server mapping. '
              'Each cell shows: index, Arabic letter, and English name.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: orderedLetters.length,
              itemBuilder: (context, index) {
                final letter = orderedLetters[index];
                final englishName = arabicToEnglishMap[letter] ?? 'Unknown';

                return Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Scheherazade',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        englishName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
