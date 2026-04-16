import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  final _supabase = Supabase.instance.client;

  // Stream mejorado para el feed que incluye los perfiles
  Stream<List<Map<String, dynamic>>> get postsStream {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.reversed.toList());
  }

  // Método para obtener los datos de los perfiles para una lista de posts
  // Usamos esto porque el .stream() de Supabase no soporta JOINs directamente
  Future<List<Map<String, dynamic>>> attachProfiles(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    
    try {
      final List<String> userIds = posts.map((p) => p['user_id'] as String).toSet().toList();
      
      final profilesData = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .inFilter('id', userIds);

      final Map<String, dynamic> profilesMap = {
        for (var p in profilesData) p['id']: p
      };

      return posts.map((post) {
        return {
          ...post,
          'profiles': profilesMap[post['user_id']]
        };
      }).toList();
    } catch (e) {
      print("Error vinculando perfiles: $e");
      return posts;
    }
  }

  // Obtener posts globales para la pestaña Explorar
  Future<List<dynamic>> getGlobalPosts({String? query}) async {
    try {
      var request = _supabase
          .from('posts')
          .select('*, profiles(username, display_name, avatar_url)');
      
      if (query != null && query.isNotEmpty) {
        request = request.or('content.ilike.%$query%, profiles.username.ilike.%$query%, profiles.display_name.ilike.%$query%');
      }

      final data = await request.order('created_at', ascending: false).limit(20);
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
