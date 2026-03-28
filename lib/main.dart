import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/marketplace_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/pantry_screen.dart';
import 'data/db.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await DB.init();
  await LocalNotificationService.init();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FreshCycleApp());
}

class FreshCycleApp extends StatelessWidget {
  const FreshCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: MaterialApp(
        title: 'FreshCycle',
        debugShowCheckedModeBanner: false,
        theme: FreshCycleTheme.theme,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // Start on Marketplace
  Key _notificationsKey = const Key('notifications');

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const PantryScreen(),
      const _PlaceholderScreen(label: 'Recipes', icon: Icons.restaurant_menu_outlined),
      const MarketplaceScreen(),
      NotificationsScreen(key: _notificationsKey),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: FreshCycleTheme.borderColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.kitchen_outlined,
                  activeIcon: Icons.kitchen_rounded,
                  label: 'Pantry',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.restaurant_menu_outlined,
                  activeIcon: Icons.restaurant_menu_rounded,
                  label: 'Recipes',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: 'Market',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.notifications_none_rounded,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Notifications',
                  isActive: _currentIndex == 3,
                  onTap: () {
                  // Force refresh notifications screen by changing key
                  setState(() {
                    _currentIndex = 3;
                    _notificationsKey = Key('notifications_${DateTime.now().millisecondsSinceEpoch}');
                  });
                },
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive
                  ? FreshCycleTheme.primary
                  : FreshCycleTheme.textHint,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? FreshCycleTheme.primary
                    : FreshCycleTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PlaceholderScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: FreshCycleTheme.textHint),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: FreshCycleTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 13,
                color: FreshCycleTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
