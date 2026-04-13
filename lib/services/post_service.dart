import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  final _supabase = Supabase.instance.client;

  // Stream para el feed en tiempo real
  Stream<List<Map<String, dynamic>>> get postsStream {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.reversed.toList());
  }

  // Obtener los posts de un usuario específico (para el perfil)
  Future<List<dynamic>> getUserPosts(String userId) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data;
    } catch (e) {
      print("Error obteniendo posts de usuario: $e");
      return [];
    }
  }

  // Subir un post (Ya lo teníamos, se mantiene igual)
  Future<bool> createPost({
    required String content,
    required dynamic imageFile,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';

      if (kIsWeb) {
        await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      } else {
        await _supabase.storage.from('posts').upload(path, imageFile as File);
      }

      final imageUrl = _supabase.storage.from('posts').getPublicUrl(path);

      await _supabase.from('posts').insert({
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
      });

      return true;
    } catch (e) {
      print("Error creando post: $e");
      return false;
    }
  }
}
