import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../widgets/menu_card.dart';
import '../pages/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the user provider
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // Removed "Quran Echo" from the title
        backgroundColor: const Color(0xFF00A896),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Show either username with logout option or login button
          if (userProvider.isLoggedIn)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  userProvider.logout();
                }
              },
              offset: const Offset(0, 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      userProvider.username ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Reduced top padding
              const SizedBox(height: 30),

              // Logo and App Name
              CircleAvatar(
                radius: 50, // Reduced size from 60 to 50
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(
                      10.0), // Reduced padding from 12 to 10
                  child: Image.asset(
                    'assets/images/quran_logo.png',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.menu_book,
                        size: 50,
                        color: Color(0xFF1F8A70)), // Reduced size from 60 to 50
                  ),
                ),
              ),
              const SizedBox(height: 20), // Reduced from 24 to 20
              Text(
                'Quran Echo',
                style: TextStyle(
                  fontSize: 32, // Reduced from 36 to 32
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 8), // Reduced from 10 to 8
              Text(
                'Learn and Memorize the Quran',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40), // Reduced from 60 to 40

              // Menu Options
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    // Added SingleChildScrollView to handle potential overflow
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Text(
                          'Select an Option',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 25), // Reduced from 30 to 25

                        // First row with Makharij and Hifz cards
                        Padding(
                          // Added padding to ensure cards don't extend beyond screen edges
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Makharij Card
                              Flexible(
                                child: MenuCard(
                                  title: 'Makharij',
                                  description: 'Learn proper pronunciation',
                                  icon: Icons.record_voice_over,
                                  color: const Color(0xFF1F8A70),
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/makharij'),
                                ),
                              ),

                              const SizedBox(
                                  width: 10), // Add spacing between cards

                              // Hifz Card
                              Flexible(
                                child: MenuCard(
                                  title: 'Hifz',
                                  description: 'Memorize the Quran',
                                  icon: Icons.auto_stories,
                                  color: const Color(0xFF00A896),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/hifz_select'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20), // Add spacing between rows

                        // Second row with Lehja and Read Quran cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Lehja Card
                              Flexible(
                                child: MenuCard(
                                  title: 'Lehja',
                                  description: 'Learn recitation styles',
                                  icon: Icons.headphones,
                                  color: const Color(0xFF05668D),
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/lehja'),
                                ),
                              ),

                              const SizedBox(
                                  width: 10), // Add spacing between cards

                              // Read Quran Card
                              Flexible(
                                child: MenuCard(
                                  title: 'Read Quran',
                                  description: 'Read the Holy Quran',
                                  icon: Icons.book,
                                  color: const Color(0xFF00A896),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/read_select'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20), // Add spacing for new row

                        // Third row with Dashboard card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Dashboard Card
                              Flexible(
                                child: MenuCard(
                                  title: 'Dashboard',
                                  description: 'Track your progress',
                                  icon: Icons.dashboard,
                                  color: const Color(0xFF025E73),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/dashboard'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
