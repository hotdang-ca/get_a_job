import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as models;

abstract class AuthRepository {
  Future<models.User?> signIn(String email, String password);
  Future<void> signOut();
  models.User? getCurrentUser();
  Stream<models.User?> authStateChanges();
  Future<void> submitAccountRequest(String name, String phone, String email);
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<models.User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return models.User(
          id: response.user!.id,
          email: response.user!.email ?? '',
          createdAt: DateTime.parse(response.user!.createdAt),
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  models.User? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return models.User(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  @override
  Stream<models.User?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;

      return models.User(
        id: user.id,
        email: user.email ?? '',
        createdAt: DateTime.parse(user.createdAt),
      );
    });
  }

  @override
  Future<void> submitAccountRequest(
      String name, String phone, String email) async {
    try {
      await _supabase.from('account_requests').insert({
        'name': name,
        'phone': phone,
        'email': email,
        'status': 'pending',
      });
    } catch (e) {
      rethrow;
    }
  }
}
