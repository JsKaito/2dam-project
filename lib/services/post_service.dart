import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  final _supabase = Supabase.instance.client;

  // Stream para el feed de seguidos (o el personal por ahora)
  Stream<List<Map<String, dynamic>>> get postsStream {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.reversed.toList());
  }

  // Obtener posts globales para la pestaña Explorar
  Future<List<dynamic>> getGlobalPosts() async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*, profiles(username, display_name, avatar_url)')
          .order('created_at', ascending: false)
          .limit(20);
      return data;
    } catch (e) {
      print("Error explorando posts: $e");
      return [];
    }
  }

  Future<List<dynamic>> getUserPosts(String userId) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data;
    } catch (e) {
      return [];
    }
  }

  Future<bool> createPost({
    required String content,
    required dynamic imageFile,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';

      if (kIsWeb) {
        await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      } else {
        await _supabase.storage.from('posts').upload(path, imageFile as File);
      }

      final imageUrl = _supabase.storage.from('posts').getPublicUrl(path);

      await _supabase.from('posts').insert({
        'user_id': user.id,
        'content': content,
        'image_url': imageUrl,
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
