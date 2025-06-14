import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/makharij_page.dart';
import 'pages/makharij_practice_page.dart';
import 'pages/hifz_page.dart';
import 'pages/recite_page.dart';  
import 'pages/recite_select_qari_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/read_surah_select_page.dart'; 
import 'pages/read_quran_page.dart'; 
import 'pages/dashboard_page.dart'; 
import 'package:provider/provider.dart';
import 'services/user_provider.dart';
import 'pages/hifz_select_surah_page.dart';
import 'package:quran_echo/services/api_service.dart';
import 'package:quran_echo/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance(); // Initialize shared preferences
  
  // Try to initialize the API service at startup
  await ApiService.initialize();
  
  // Start background sync process for any pending offline changes
  SyncService.startBackgroundSync();
  
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
        '/hifz_select': (context) => const HifzSelectSurahPage(),
        '/hifz': (context) => const HifzPage(),
        '/recite': (context) => const RecitePage(),
        '/lehja': (context) => const ReciteSelectQariPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/read_select': (context) => const ReadSurahSelectPage(), // Add this route
        '/read_quran': (context) => ReadQuranPage(
          surahInfo: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
        ), // Add this route
        '/dashboard': (context) => const DashboardPage(), // Add this route
      },
    );
  }
}