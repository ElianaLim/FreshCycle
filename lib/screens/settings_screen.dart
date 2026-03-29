import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _locationServices = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _SectionHeader(title: 'Notifications'),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive alerts for new listings and messages',
              trailing: Switch(
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                },
                activeThumbColor: FreshCycleTheme.primary,
              ),
            ),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Receive weekly summaries and promotions',
              trailing: Switch(
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                },
                activeThumbColor: FreshCycleTheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Location Section
            _SectionHeader(title: 'Location'),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              subtitle: 'Show nearby listings in your area',
              trailing: Switch(
                value: _locationServices,
                onChanged: (value) {
                  setState(() => _locationServices = value);
                },
                activeThumbColor: FreshCycleTheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // About & Support Section
            _SectionHeader(title: 'About & Support'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: null,
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'View our terms and conditions',
              onTap: () => _showStubDialog('Terms of Service'),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'View our privacy policy',
              onTap: () => _showStubDialog('Privacy Policy'),
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or contact support',
              onTap: () => _showStubDialog('Help & Support'),
            ),
            const SizedBox(height: 24),

            // Account Section
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              titleColor: FreshCycleTheme.urgencyCritical,
              onTap: () => _showDeleteAccountDialog(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showStubDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('$title page is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement actual account deletion
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(
              foregroundColor: FreshCycleTheme.urgencyCritical,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Deletion'),
        content: const Text(
          'This feature is coming soon. Please contact support to delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FreshCycleTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: titleColor ?? FreshCycleTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? FreshCycleTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: FreshCycleTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: FreshCycleTheme.textHint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
