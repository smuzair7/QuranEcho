import 'package:flutter/material.dart';
import 'makharij_page.dart';

class MakharijLettersPage extends StatefulWidget {
  const MakharijLettersPage({super.key});

  @override
  _MakharijLettersPageState createState() => _MakharijLettersPageState();
}

class _MakharijLettersPageState extends State<MakharijLettersPage> {
  final List<String> letters = [
   'ع', // 0 - Aain
    'ا', // 1 - Alif
    'ب', // 2 - Ba
    'د', // 3 - Dal
    'ض', // 4 - Duad
    'ف', // 5 - Faa
    'غ', // 6 - Ghain
    'ه', // 7 - Haa
    'ح', // 8 - Hha
    'ج', // 9 - Jeem
    'ك', // 10 - Kaif
    'خ', // 11 - Kha
    'ل', // 12 - Laam
    'م', // 13 - Meem
    'ن', // 14 - Noon
    'ق', // 15 - Qauf
    'ر', // 16 - Raa
    'ث', // 17 - Sa (ث)
    'ص', // 18 - Saud
    'س', // 19 - Seen (س)
    'ش', // 20 - Sheen
    'ت', // 21 - Ta
    'ط', // 22 - Tua
    'و', // 23 - Wao
    'ي', // 24 - Yaa
    'ز', // 25 - Zaa
    'ذ', // 26 - Zhal
    'ظ' // 27 - Zua
  ];

  int? selectedIndex;

  void selectLetter(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void navigateToQuiz() {
    Navigator.pushNamed(context, '/makharij_test');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Makharij Letters"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: letters.length,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedIndex;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.orange[800] : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isSelected ? 4 : 2,
                    ),
                    onPressed: () => selectLetter(index),
                    child: Text(
                      letters[index],
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: navigateToQuiz,
                child: const Text("Take Quiz"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MakharijPracticePage extends StatefulWidget {
  const MakharijPracticePage({super.key});

  @override
  State<MakharijPracticePage> createState() => _MakharijPracticePageState();
}

class _MakharijPracticePageState extends State<MakharijPracticePage> {
  // Updated letters list to match EXACTLY the order in app.py id_to_harf mapping
  final List<String> letters = [
    'ع', // 0 - Aain
    'ا', // 1 - Alif
    'ب', // 2 - Ba
    'د', // 3 - Dal
    'ض', // 4 - Duad
    'ف', // 5 - Faa
    'غ', // 6 - Ghain
    'ه', // 7 - Haa
    'ح', // 8 - Hha
    'ج', // 9 - Jeem
    'ك', // 10 - Kaif
    'خ', // 11 - Kha
    'ل', // 12 - Laam
    'م', // 13 - Meem
    'ن', // 14 - Noon
    'ق', // 15 - Qauf
    'ر', // 16 - Raa
    'ث', // 17 - Sa (ث)
    'ص', // 18 - Saud
    'س', // 19 - Seen (س)
    'ش', // 20 - Sheen
    'ت', // 21 - Ta
    'ط', // 22 - Tua
    'و', // 23 - Wao
    'ي', // 24 - Yaa
    'ز', // 25 - Zaa
    'ذ', // 26 - Zhal
    'ظ' // 27 - Zua
  ];

  int? selectedIndex;

  void selectLetter(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void navigateToRecording() {
    if (selectedIndex != null) {
      // Navigate to recording page with the selected letter
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MakharijPage(
              letter: letters[selectedIndex!],
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Makharij Letters"),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add debug button to verify letter order
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.pushNamed(context, '/makharij_debug');
            },
            tooltip: 'Debug Letter Order',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Practice Pronunciation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Select a letter to study its pronunciation point',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Directionality(
                // Use RTL for proper Arabic letter order display
                textDirection: TextDirection.rtl,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        4, // Changed to 4 letters per row for better layout
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: letters.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedIndex;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF00A896)
                            : const Color(0xFF1F8A70),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isSelected ? 4 : 2,
                        padding: EdgeInsets
                            .zero, // Remove padding to fit larger letters
                      ),
                      onPressed: () => selectLetter(index),
                      child: Center(
                        child: Text(
                          letters[index],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Scheherazade',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Practice button that appears after selection
            if (selectedIndex != null) ...[
              // Reset to LTR for the button text
              Directionality(
                textDirection: TextDirection.ltr,
                child: ElevatedButton.icon(
                  onPressed: navigateToRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.mic),
                  label: const Text(
                    "Practice Recording",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
