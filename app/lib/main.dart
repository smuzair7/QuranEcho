import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/makharij_page.dart';
import 'pages/makharij_practice_page.dart';
import 'pages/hifz_page.dart';
import 'pages/recite_page.dart';  
import 'pages/recite_select_qari_page.dart';
import 'pages/login_page.dart';  // Add this import
import 'pages/signup_page.dart';  // Add this import
import 'package:provider/provider.dart';
import 'services/user_provider.dart';
import 'pages/hifz_select_surah_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const QuranEchoApp(),
    ),
  );
}

class QuranEchoApp extends StatelessWidget {
  const QuranEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Echo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Scheherazade', // Uncommented since font will be added
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F8A70),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F8A70),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      
      routes: {
        '/': (context) => const HomePage(),
        '/makharij': (context) => const MakharijPracticePage(),
        '/hifz_select': (context) => const HifzSelectSurahPage(), // Add this line
        '/hifz': (context) => const HifzPage(),
        '/recite': (context) => const RecitePage(),
        '/lehja': (context) => const ReciteSelectQariPage(),
        '/login': (context) => const LoginPage(),  // Add login route
        '/signup': (context) => const SignupPage(), // Add signup route
      },
    );
  }
}