import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final User? currentUser;

  const ProfileScreen({
    super.key,
    required this.onLogin,
    required this.onLogout,
    this.currentUser,
  });

  bool get isLoggedIn => currentUser != null;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return _LoginScreen(onLogin: onLogin);
    }
    return _ProfileContent(
      user: currentUser!,
      onLogout: onLogout,
    );
  }
}

class _LoginScreen extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginScreen({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: FreshCycleTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 40,
                    color: FreshCycleTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to FreshCycle',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to manage your profile,\npantry, and listings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: FreshCycleTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FreshCycleTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // For demo, just sign in directly
                    onLogin();
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: FreshCycleTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

  const _ProfileContent({
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Generate avatar colors based on user id
    final idx = user.id.hashCode.abs() % FreshCycleTheme.avatarBgs.length;
    final avatarBg = FreshCycleTheme.avatarBgs[idx];
    final avatarFg = FreshCycleTheme.avatarFgs[idx];

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: avatarFg,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: FreshCycleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // User Email
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: FreshCycleTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu Items
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      onTap: () {
                        // TODO: Implement edit profile
                      },
                    ),
                    
                    _MenuItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'My Listings',
                      onTap: () {
                        // TODO: Navigate to listings
                      },
                    ),
                    _MenuItem(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Saved Items',
                      onTap: () {
                        // TODO: Navigate to saved items
                      },
                    ),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        // TODO: Navigate to settings
                      },
                    ),
                    const Spacer(),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FreshCycleTheme.urgencyCritical,
                          side: const BorderSide(
                            color: FreshCycleTheme.urgencyCritical,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: FreshCycleTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: FreshCycleTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}