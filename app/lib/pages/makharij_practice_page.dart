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

    // Add a new list that defines the display order
  final List<int> arabicAlphabetOrder = [
    1,  // Alif (index 1 in your original list)
    2,  // Ba (index 2)
    21, // Ta (index 21)
    17, // Sa/Tha (index 17)
    9,  // Jeem (index 9)
    8,  // Hha (index 8)
    11, // Kha (index 11)
    3,  // Dal (index 3)
    26, // Zhal (index 26)
    16, // Raa (index 16)
    25, // Zaa (index 25)
    19, // Seen (index 19)
    20, // Sheen (index 20)
    18, // Saud (index 18)
    4,  // Duad (index 4)
    22, // Tua (index 22)
    27, // Zua (index 27)
    0,  // Aain (index 0)
    6,  // Ghain (index 6)
    5,  // Faa (index 5)
    15, // Qauf (index 15)
    10, // Kaif (index 10)
    12, // Laam (index 12)
    13, // Meem (index 13)
    14, // Noon (index 14)
    7,  // Haa (index 7)
    23, // Wao (index 23)
    24  // Yaa (index 24)
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
  // Add this list to your class
  final List<int> arabicAlphabetOrder = [
    1,  // Alif (index 1)
    2,  // Ba (index 2)
    21, // Ta (index 21)
    17, // Sa/Tha (index 17)
    9,  // Jeem (index 9)
    8,  // Hha (index 8)
    11, // Kha (index 11)
    3,  // Dal (index 3)
    26, // Zhal (index 26)
    16, // Raa (index 16)
    25, // Zaa (index 25)
    19, // Seen (index 19)
    20, // Sheen (index 20)
    18, // Saud (index 18)
    4,  // Duad (index 4)
    22, // Tua (index 22)
    27, // Zua (index 27)
    0,  // Aain (index 0)
    6,  // Ghain (index 6)
    5,  // Faa (index 5)
    15, // Qauf (index 15)
    10, // Kaif (index 10)
    12, // Laam (index 12)
    13, // Meem (index 13)
    14, // Noon (index 14)
    7,  // Haa (index 7)
    23, // Wao (index 23)
    24  // Yaa (index 24)
  ];
  
  // Your existing code follows...
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
                    crossAxisCount: 4,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: letters.length,
                  itemBuilder: (context, index) {
                    // Use the mapped index to get the letter in correct Arabic order
                    final mappedIndex = arabicAlphabetOrder[index];
                    final isSelected = mappedIndex == selectedIndex;
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
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => selectLetter(mappedIndex), // Use the original index for selection
                      child: Center(
                        child: Text(
                          letters[mappedIndex], // Display the letter using the mapped index
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
