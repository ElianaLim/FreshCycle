import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DB {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call DB.init() first.');
    }
    return _client!;
  }
  
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_KEY'] ?? '';
    
    await Supabase.initialize(
      url: url,
      anonKey: key,
    );
    
    _client = Supabase.instance.client;
  }
  
  // Register new user - insert into profiles table
  static Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
    required String number,
  }) async {
    try {
      // First, create auth user
      final authResponse = await _client!.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        return null;
      }
      
      // Then insert into profiles table
      final userId = authResponse.user!.id;
      final initials = _getInitials(name);
      
      // Set the session to establish auth context for RLS
      final session = authResponse.session;
      final refreshToken = session?.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client!.auth.setSession(refreshToken);
      }
      
      await _client!.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'initials': initials,
        'created_at': DateTime.now().toIso8601String(),
        'phone_number': number,
      });
      
      return {
        'id': userId,
        'name': name,
        'email': email,
        'initials': initials,
        'phone_number': number,
      };
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }
  
  // Login user - simple email/password check against profiles table
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // First, authenticate with Supabase Auth
      final authResponse = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        return null;
      }
      
      // Get user profile from profiles table
      final response = await _client!
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
  
  // Logout
  static Future<void> logout() async {
    await _client!.auth.signOut();
  }
  
  // Change password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First verify the current password by trying to sign in
      final verifyResult = await _client!.auth.signInWithPassword(
        email: _client!.auth.currentUser?.email ?? '',
        password: currentPassword,
      );
      
      if (verifyResult.user == null) {
        return false;
      }
      
      // Now update the password
      final response = await _client!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      return response.user != null;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }
  
  // Get current user
  static Map<String, dynamic>? getCurrentUser() {
    final user = _client!.auth.currentUser;
    return user != null ? {'id': user.id, 'email': user.email} : null;
  }
  
  // Get user profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }
  
  // Update user profile
  static Future<bool> updateProfile({
    required String userId,
    String? name,
    String? initials,
    String? phoneNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
        if (initials == null) {
          updateData['initials'] = _getInitials(name);
        }
      }
      if (initials != null) {
        updateData['initials'] = initials;
      }
      if (phoneNumber != null) {
        updateData['phone_number'] = phoneNumber;
      }
      
      if (updateData.isEmpty) return true;
      
      await _client!.from('profiles').update(updateData).eq('id', userId);
      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
  
  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}
