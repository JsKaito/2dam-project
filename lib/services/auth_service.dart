import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // REGISTRO RESTAURADO
  Future<bool> register(String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      return response.user != null;
    } catch (e) {
      print("Error en registro: $e");
      return false;
    }
  }

  // LOGIN CON FORZADO DE MFA
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
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
      if (e.message.contains("mfa")) return "mfa_required";
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOTP(String code) async {
    try {
      final factors = await _supabase.auth.mfa.listFactors();
      final verifiedFactors = factors.all.where((f) => f.status == FactorStatus.verified).toList();
      
      if (verifiedFactors.isEmpty) return false;
      
      final factorId = verifiedFactors.first.id;
      final challenge = await _supabase.auth.mfa.challenge(factorId: factorId);
      
      await _supabase.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );
      return true;
    } catch (e) {
      print("Error verify OTP: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
