import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService({required this.supabase});

  Map<String, dynamic>? _cachedProfile;

  // Login dengan email dan password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Fetch profile setelah login
      await getProfile(forceRefresh: true);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    _cachedProfile = null;
    await supabase.auth.signOut();
  }

  // Ambil profil user yang sedang login
  Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) async {
    if (_cachedProfile != null && !forceRefresh) return _cachedProfile;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response =
          await supabase.from('profiles').select().eq('id', user.id).single();
      _cachedProfile = response;
      return _cachedProfile;
    } catch (e) {
      return null;
    }
  }

  // Cek apakah user adalah admin
  bool get isAdmin {
    final role = _cachedProfile?['role'];
    final email = currentUser?.email;
    return role == 'admin' || email == 'admin@itzin.com';
  }

  // Ambil user yang sedang login
  User? get currentUser => supabase.auth.currentUser;

  // Cek apakah ada sesi aktif
  bool get hasSession => supabase.auth.currentSession != null;

  // Stream perubahan auth state
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
