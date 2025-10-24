import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Sign in
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );

    // Insert into users table
    if (response.user != null) {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
      });
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;
}
