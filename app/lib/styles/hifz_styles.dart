import 'package:flutter/material.dart';

class HifzStyles {
  // Colors
  static const Color primaryColor = Color(0xFF00A896);
  static const Color secondaryColor = Color(0xFF05668D);
  static const Color tertiaryColor = Color(0xFF028090);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color darkGray = Color(0xFF212121);
  static const Color mediumGray = Color(0xFF1E1E1E);
  static const Color lightGray = Color(0xFF333333);
  static const Color borderColor = Color(0xFF555555);

  // Gradients
  static LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.black87,
      backgroundColor,
    ],
  );

  // Text Styles
  static const TextStyle ayahTextStyle = TextStyle(
    fontSize: 28,
    fontFamily: 'Scheherazade',
    height: 2.0,
    color: Colors.black,
  );

  static const TextStyle currentAyahTextStyle = TextStyle(
    fontSize: 26,
    fontFamily: 'Scheherazade',
    height: 1.8,
    color: Colors.black,
  );

  static const TextStyle regularAyahTextStyle = TextStyle(
    fontSize: 20,
    fontFamily: 'Scheherazade',
    height: 1.8,
    color: Colors.black,
  );

  static TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle progressTitleStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle dropdownLabelStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    color: Colors.white70,
  );

  static const TextStyle dropdownTextStyle = TextStyle(
    color: Colors.white,
  );

  static TextStyle ayahNumberStyle(bool isCurrent) => TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  static TextStyle ayahLabelStyle(bool isCurrent, BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
    color: isCurrent ? primaryColor : Colors.grey.shade800,
  );

  static TextStyle transcriptionHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.blue.shade800,
  );

  // Button Styles
  static ButtonStyle recordButtonStyle(bool isRecording) => ElevatedButton.styleFrom(
    backgroundColor: isRecording ? Colors.red : secondaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.all(12),
    shape: const CircleBorder(),
  );

  static ButtonStyle playButtonStyle(bool isPlaying) => ElevatedButton.styleFrom(
    backgroundColor: isPlaying ? Colors.orange : tertiaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.all(12),
    shape: const CircleBorder(),
  );

  static ButtonStyle navigationButtonStyle({bool isPrimary = false}) => ElevatedButton.styleFrom(
    backgroundColor: isPrimary ? primaryColor : Colors.grey.shade700,
    foregroundColor: Colors.white,
  );
  
  static ButtonStyle reviseButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  static ButtonStyle reviewButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.all(12),
    shape: const CircleBorder(),
  );

  static ButtonStyle saveButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  // Container Decorations
  static BoxDecoration ayahCardDecoration(bool isCurrent, BuildContext context) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      if (isCurrent)
        BoxShadow(
          color: primaryColor.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
    ],
    border: isCurrent 
      ? Border.all(color: primaryColor, width: 2) 
      : null,
  );
  
  static BoxDecoration progressContainerDecoration = const BoxDecoration(
    color: darkGray,
  );
  
  static BoxDecoration dropdownContainerDecoration = BoxDecoration(
    color: lightGray,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
  );
  
  static BoxDecoration navigationBarDecoration = BoxDecoration(
    color: darkGray,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        spreadRadius: 1,
        blurRadius: 5,
        offset: const Offset(0, -3),
      ),
    ],
  );
  
  static BoxDecoration revisionBarDecoration = BoxDecoration(
    color: mediumGray,
    border: const Border(
      top: BorderSide(color: lightGray, width: 1),
      bottom: BorderSide(color: lightGray, width: 1),
    ),
  );
  
  static BoxDecoration transcriptionContainerDecoration = BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.blue.shade200),
  );

  // Helper methods for styled widgets
  static Widget buildAyahNumberContainer(int number, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrent ? primaryColor : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
      child: Text(
        number.toString(),
        style: ayahNumberStyle(isCurrent),
      ),
    );
  }
  
  static Widget buildProgressIndicator(double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade800,
        minHeight: 8,
      ),
    );
  }
  
  static Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }
  
  static TextSpan buildHighlightedTextSpan(String word, bool isCorrect, bool isLast) {
    return TextSpan(
      text: isLast ? word : '$word ',
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'Scheherazade',
        fontWeight: FontWeight.w500,
        color: isCorrect ? Colors.green : Colors.red,
      ),
    );
  }
}
