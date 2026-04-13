import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // Obtener el perfil del usuario actual
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      print("Error obteniendo perfil: $e");
      return null;
    }
  }

  // Actualizar el perfil
  Future<bool> updateProfile({
    required String username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').update({
        'username': username,
        'bio': bio,
        'avatar_url': avatarUrl,
      }).eq('id', userId);
      return true;
    } catch (e) {
      print("Error actualizando perfil: $e");
      return false;
    }
  }
}
