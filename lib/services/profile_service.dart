import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService {
  final _supabase = Supabase.instance.client;

  // Stream seguro: Si no hay usuario, devuelve un stream vacío en lugar de explotar
  Stream<Map<String, dynamic>> get profileStream {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((event) => event.isNotEmpty ? event.first : {});
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final data = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();
      return data;
    } catch (e) {
      print("Error obteniendo perfil: $e");
      return null;
    }
  }

  Future<String?> uploadAvatar(dynamic imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/${user.id}/$fileName';

      if (kIsWeb) {
        await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      } else {
        await _supabase.storage.from('posts').upload(path, imageFile as File);
      }

      return _supabase.storage.from('posts').getPublicUrl(path);
    } catch (e) {
      print("Error subiendo avatar: $e");
      return null;
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final updates = {
        'username': username,
        'display_name': displayName,
        'bio': bio,
      };
      
      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      await _supabase.from('profiles').update(updates).eq('id', user.id);
      return true;
    } catch (e) {
      print("Error actualizando perfil: $e");
      return false;
    }
  }
}
