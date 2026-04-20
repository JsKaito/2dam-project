import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  final _supabase = Supabase.instance.client;

  // Stream para el feed de Inicio (Mis posts + Seguidos)
  Stream<List<Map<String, dynamic>>> getHomeFeedStream(String userId) {
    // 1. Obtenemos el stream de todos los posts
    // 2. Filtramos localmente por simplicidad y tiempo real (se puede optimizar con una View en el futuro)
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .asyncMap((allPosts) async {
          // Obtenemos a quién seguimos
          final followingData = await _supabase
              .from('followers')
              .select('following_id')
              .eq('follower_id', userId);
          
          final followingIds = (followingData as List).map((f) => f['following_id'] as String).toList();
          followingIds.add(userId); // Nos incluimos a nosotros mismos

          // Filtramos y devolvemos
          return allPosts.where((post) => followingIds.contains(post['user_id'])).toList().reversed.toList();
        });
  }

  // Stream global para Explorar (Todo el contenido)
  Stream<List<Map<String, dynamic>>> get postsStream {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.reversed.toList());
  }

  // Vincular perfiles a los posts para mostrar nombres/fotos
  Future<List<Map<String, dynamic>>> attachProfiles(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    try {
      final List<String> userIds = posts.map((p) => p['user_id'] as String).toSet().toList();
      final profilesData = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .inFilter('id', userIds);

      final Map<String, dynamic> profilesMap = {for (var p in profilesData) p['id']: p};

      return posts.map((post) {
        return {...post, 'profiles': profilesMap[post['user_id']]};
      }).toList();
    } catch (e) {
      return posts;
    }
  }

  Future<List<dynamic>> getGlobalPosts({String? query}) async {
    try {
      var request = _supabase.from('posts').select('*, profiles(username, display_name, avatar_url)');
      if (query != null && query.isNotEmpty) {
        request = request.ilike('content', '%$query%');
      }
      return await request.order('created_at', ascending: false).limit(20);
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getUserPosts(String userId) async {
    try {
      return await _supabase.from('posts').select('*').eq('user_id', userId).order('created_at', ascending: false);
    } catch (e) {
      return [];
    }
  }

  Future<bool> createPost({required String content, required dynamic imageFile}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';
      if (kIsWeb) await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      else await _supabase.storage.from('posts').upload(path, imageFile as File);
      final imageUrl = _supabase.storage.from('posts').getPublicUrl(path);
      await _supabase.from('posts').insert({'user_id': user.id, 'content': content, 'image_url': imageUrl});
      return true;
    } catch (e) {
      return false;
    }
  }
}
