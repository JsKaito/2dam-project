import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Registrar un nuevo usuario en Supabase Auth
  Future<bool> register(String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Metadatos opcionales
      );
      return response.user != null;
    } catch (e) {
      print("Error en registro Supabase: $e");
      return false;
    }
  }

  // Iniciar sesión con Supabase Auth
  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print("Error en login Supabase: $e");
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Obtener el usuario actual logueado
  User? get currentUser => _supabase.auth.currentUser;
}
