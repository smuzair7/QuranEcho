import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/user_provider.dart';
import '../widgets/menu_card.dart';
import '../widgets/geometric_lattice.dart';
import '../theme/app_theme.dart';
import '../pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
        child: Column(
          children: [
            _Header(userProvider: userProvider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Practice', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Pick up where you left off, or start something new.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkSoft,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MenuCard(
                      title: 'Learn Makharij',
                      description: 'Practice the articulation points of each letter',
                      icon: Icons.record_voice_over_rounded,
                      color: AppColors.gold,
                      onTap: () => Navigator.pushNamed(context, '/makharij'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MenuCard(
                      title: 'Hifz Quran',
                      description: 'Memorize ayahs and track what you’ve retained',
                      icon: Icons.auto_stories_rounded,
                      color: AppColors.palm,
                      onTap: () => Navigator.pushNamed(context, '/hifz_select'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MenuCard(
                      title: 'Imitate Lehja',
                      description: 'Match your recitation style to a reciter',
                      icon: Icons.surround_sound_rounded,
                      color: AppColors.sage,
                      onTap: () => Navigator.pushNamed(context, '/lehja'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MenuCard(
                      title: 'Read Quran',
                      description: 'Browse and read any surah at your own pace',
                      icon: Icons.book_rounded,
                      color: AppColors.palmDeep,
                      onTap: () => Navigator.pushNamed(context, '/read_select'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserProvider userProvider;

  const _Header({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.palmDeep,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GeometricLattice(color: Colors.white.withOpacity(0.05)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderIconButton(
                        icon: Icons.dashboard_rounded,
                        tooltip: 'Dashboard',
                        onTap: () => Navigator.pushNamed(context, '/dashboard'),
                      ),
                      if (userProvider.isLoggedIn)
                        _ProfileMenu(userProvider: userProvider)
                      else
                        _HeaderIconButton(
                          icon: Icons.login_rounded,
                          tooltip: 'Log in',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.parchment,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/quran-echo-logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.menu_book_rounded,
                            size: 28,
                            color: AppColors.palm,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quran Echo',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.parchment,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Learn and memorize the Quran',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.parchment.withOpacity(0.75),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: AppColors.parchment),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final UserProvider userProvider;

  const _ProfileMenu({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'logout') {
            userProvider.logout();
          }
        },
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        icon: const Icon(Icons.person_rounded, color: AppColors.parchment),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.palmSoft,
                  child: Text(
                    userProvider.username?.isNotEmpty == true
                        ? userProvider.username![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.palm,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  userProvider.username ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.claySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: AppColors.clay, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Log out'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
