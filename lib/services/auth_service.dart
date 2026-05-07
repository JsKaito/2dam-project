import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _accountsKey = 'saved_accounts';

  String _friendlyAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('rate limit')) return "Demasiados intentos. Espera un momento.";
    if (lower.contains('invalid login credentials')) return "Correo o contrasena incorrectos.";
    if (lower.contains('email not confirmed')) return "Confirma tu correo para continuar.";
    if (lower.contains('already registered') || lower.contains('user already registered')) {
      return "Este correo ya esta registrado.";
    }
    if (lower.contains('password') && lower.contains('short')) return "La contrasena no cumple los requisitos.";
    if (lower.contains('email') && lower.contains('invalid')) return "El correo no es valido.";
    return "No pudimos completar la operacion. Intentalo de nuevo.";
  }

  Future<dynamic> register(String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
        emailRedirectTo: 'io.supabase.artistscottage://login-callback',
      );
      return response.user != null;
    } on AuthException catch (e) {
      return _friendlyAuthMessage(e.message);
    } catch (e) {
      return "No pudimos crear tu cuenta. Intentalo de nuevo.";
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
      return _friendlyAuthMessage(e.message);
    } catch (e) {
      return "No pudimos iniciar sesion. Intentalo de nuevo.";
    }
  }

  /// Envía un correo de recuperación de contraseña.
  Future<dynamic> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.artistscottage://login-callback',
      );
      return true;
    } on AuthException catch (e) {
      return _friendlyAuthMessage(e.message);
    } catch (e) {
      return "No pudimos enviar el correo. Intentalo de nuevo.";
    }
  }

  // --- MULTI-CUENTA LOGIC ---

  Future<void> saveCurrentAccount() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      if (session == null || user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final String? accountsJson = prefs.getString(_accountsKey);
      List<dynamic> accounts = accountsJson != null ? jsonDecode(accountsJson) : [];

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

      final res = await _supabase.auth.setSession(refreshToken);
      if (res.session != null) {
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
