import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _accountsKey = 'saved_accounts';

  Future<dynamic> register(String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
        emailRedirectTo: 'io.supabase.artistscottage://login-callback/',
      );
      return response.user != null;
    } on AuthException catch (e) {
      if (e.message.contains("rate limit exceeded")) {
        return "Demasiados intentos. Por favor, espera un momento.";
      }
      return e.message;
    } catch (e) {
      return "Error inesperado al registrar.";
    }
  }

  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
        await saveCurrentAccount();
        final factors = await _supabase.auth.mfa.listFactors();
        final hasVerifiedMfa = factors.all.any((f) => f.status == FactorStatus.verified);
        final currentLevel = _supabase.auth.currentSession?.user.appMetadata['aal'];
        
        if (hasVerifiedMfa && currentLevel != 'aal2') {
          return "mfa_required";
        }
        return true;
      }
      return false;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains("mfa")) return "mfa_required";
      return e.message;
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  // --- MULTI-CUENTA LOGIC OPTIMIZADA ---

  Future<void> saveCurrentAccount() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      if (session == null || user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final String? accountsJson = prefs.getString(_accountsKey);
      List<dynamic> accounts = accountsJson != null ? jsonDecode(accountsJson) : [];

      // Intentar obtener datos básicos del perfil (sin bloquear si falla)
      Map<String, dynamic>? profile;
      try {
        profile = await _supabase.from('profiles').select('username, avatar_url, display_name').eq('id', user.id).maybeSingle();
      } catch (_) {}
      
      final Map<String, dynamic> accountData = {
        'id': user.id,
        'email': user.email,
        'username': profile?['username'] ?? user.email,
        'display_name': profile?['display_name'] ?? profile?['username'] ?? "Usuario",
        'avatar_url': profile?['avatar_url'],
        'refresh_token': session.refreshToken,
      };

      final index = accounts.indexWhere((acc) => acc['id'] == user.id);
      if (index != -1) accounts[index] = accountData;
      else accounts.add(accountData);

      await prefs.setString(_accountsKey, jsonEncode(accounts));
    } catch (e) {
      print("Error guardando cuenta: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString(_accountsKey);
    if (accountsJson == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(accountsJson));
    } catch (e) {
      return [];
    }
  }

  Future<bool> switchAccount(Map<String, dynamic> account) async {
    try {
      final String? refreshToken = account['refresh_token'];
      if (refreshToken == null) return false;

      // Cambiar sesión
      final res = await _supabase.auth.setSession(refreshToken);
      if (res.session != null) {
        // Actualizar datos de cuenta en segundo plano, sin esperar
        saveCurrentAccount();
        return true;
      }
      return false;
    } catch (e) {
      print("Error switching account: $e");
      return false;
    }
  }

  Future<void> removeAccount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString(_accountsKey);
    if (accountsJson == null) return;
    
    List<dynamic> accounts = jsonDecode(accountsJson);
    accounts.removeWhere((acc) => acc['id'] == userId);
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  // --- FIN MULTI-CUENTA ---

  Future<bool> verifyOTP(String code) async {
    try {
      final factors = await _supabase.auth.mfa.listFactors();
      final verifiedFactors = factors.all.where((f) => f.status == FactorStatus.verified).toList();
      if (verifiedFactors.isEmpty) return false;
      
      final factorId = verifiedFactors.first.id;
      final challenge = await _supabase.auth.mfa.challenge(factorId: factorId);
      await _supabase.auth.mfa.verify(factorId: factorId, challengeId: challenge.id, code: code);
      return true;
    } catch (e) { return false; }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
