import 'package:flutter/material.dart';
import 'makharij_page.dart';

class MakharijLettersPage extends StatefulWidget {
  @override
  _MakharijLettersPageState createState() => _MakharijLettersPageState();
}

class _MakharijLettersPageState extends State<MakharijLettersPage> {
  final List<String> letters = [
    'ت', 'ب', 'ا', 'ح', 'ج', 'ث', 'ذ', 'د', 'خ', 'س', 'ز', 'ر', 'ض', 'ص',
    'ش', 'ع', 'ظ', 'ط', 'ق', 'ف', 'غ', 'م', 'ل', 'ك', 'و', 'ه', 'ن', 'ي'
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
                      backgroundColor: isSelected ? Colors.orange[800] : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isSelected ? 4 : 2,
                    ),
                    onPressed: () => selectLetter(index),
                    child: Text(
                      letters[index],
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  final List<String> letters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص',
    'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'
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
        )
      );
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
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Select a letter to study its pronunciation point',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
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
                      backgroundColor: isSelected ? const Color(0xFF00A896) : const Color(0xFF1F8A70),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isSelected ? 4 : 2,
                    ),
                    onPressed: () => selectLetter(index),
                    child: Text(
                      letters[index],
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Scheherazade',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Practice button that appears after selection
            if (selectedIndex != null) ...[
              ElevatedButton.icon(
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
            ],
          ],
        ),
      ),
    );
  }
}