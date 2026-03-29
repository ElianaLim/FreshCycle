import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  bool _isInitialized = false;
  bool _obscureNewPassword = true;
  bool _obscureCurrentPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.number;
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    
    // Update profile fields
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    // Handle password change if provided
    if (_newPasswordController.text.isNotEmpty) {
      final passwordSuccess = await auth.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      
      if (!passwordSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Failed to change password'),
            backgroundColor: FreshCycleTheme.urgencyCritical,
          ),
        );
        return;
      }
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: FreshCycleTheme.primary,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile'),
          backgroundColor: FreshCycleTheme.urgencyCritical,
        ),
      );
    }
  }
// # This function was created using Generative AI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return TextButton(
                onPressed: auth.isLoading ? null : _saveProfile,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Avatar
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.user;
                if (user == null) return const SizedBox.shrink();
                
                final idx = user.id.hashCode.abs() % FreshCycleTheme.avatarBgs.length;
                final avatarBg = FreshCycleTheme.avatarBgs[idx];
                final avatarFg = FreshCycleTheme.avatarFgs[idx];

                return Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: avatarBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: avatarFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Name Field (editable)
            _buildEditableField(
              label: 'Full Name',
              controller: _nameController,
              hintText: 'Enter your full name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field (locked/read-only)
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.user;
                if (user == null) return const SizedBox.shrink();
                
                return _buildReadOnlyField(
                  label: 'Email',
                  value: user.email,
                  icon: Icons.email_outlined,
                );
              },
            ),
            const SizedBox(height: 16),

            // Phone Number Field (editable)
            _buildEditableField(
              label: 'Phone Number',
              controller: _phoneController,
              hintText: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Password Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FreshCycleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter current password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                        },
                      ),
                    ),
                    obscureText: _obscureCurrentPassword,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password (optional)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureNewPassword = !_obscureNewPassword);
                        },
                      ),
                    ),
                    obscureText: _obscureNewPassword,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FreshCycleTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              prefixIcon: Icon(icon, size: 20, color: FreshCycleTheme.textHint),
            ),
            keyboardType: keyboardType,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FreshCycleTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 20, color: FreshCycleTheme.textHint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: FreshCycleTheme.textHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}