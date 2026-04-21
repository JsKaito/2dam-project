import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  final _supabase = Supabase.instance.client;

  // Función auxiliar para limpiar mapas de Supabase (Evita TypeError en Web)
  Map<String, dynamic> _cleanMap(dynamic data) {
    if (data == null) return {};
    final Map<dynamic, dynamic> original = data as Map;
    return original.map((key, value) => MapEntry(key.toString(), value));
  }

  // Obtener las palabras ocultas del usuario actual
  Future<List<String>> _getHiddenWords() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await _supabase.from('profiles').select('hidden_words').eq('id', userId).maybeSingle();
      final String words = res?['hidden_words'] ?? '';
      return words.split(',').map((w) => w.trim().toLowerCase()).where((w) => w.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  // Verifica si el contenido contiene alguna palabra prohibida
  bool _shouldFilter(String content, List<String> hiddenWords) {
    if (content.isEmpty || hiddenWords.isEmpty) return false;
    final lowerContent = content.toLowerCase();
    for (var word in hiddenWords) {
      if (lowerContent.contains(word)) return true;
    }
    return false;
  }

  Stream<List<Map<String, dynamic>>> getHomeFeedStream(String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((allPosts) async {
          final hiddenWords = await _getHiddenWords();
          
          final followingData = await _supabase
              .from('followers')
              .select('following_id')
              .eq('follower_id', userId);
          
          final followingIds = (followingData as List).map((f) => f['following_id'] as String).toList();
          followingIds.add(userId);

          // Filtramos por seguidos Y por palabras ocultas
          final filteredPosts = allPosts.where((post) {
            final isFollowed = followingIds.contains(post['user_id']);
            final hasForbiddenWord = _shouldFilter(post['content'] ?? '', hiddenWords);
            return isFollowed && !hasForbiddenWord;
          }).toList();

          return await _attachCounts(filteredPosts);
        });
  }

  Future<List<Map<String, dynamic>>> _attachCounts(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    final currentUserId = _supabase.auth.currentUser?.id;
    
    final List<Map<String, dynamic>> enrichedPosts = [];
    for (var post in posts) {
      try {
        final postMap = _cleanMap(post);
        final likes = await _supabase.from('post_likes').select('user_id').eq('post_id', postMap['id']);
        final comments = await _supabase.from('comments').select('id').eq('post_id', postMap['id']);
        
        bool isLiked = false;
        if (currentUserId != null) {
          final myLike = await _supabase.from('post_likes').select().eq('post_id', postMap['id']).eq('user_id', currentUserId).maybeSingle();
          isLiked = myLike != null;
        }

        postMap['likes_count'] = (likes as List).length;
        postMap['comments_count'] = (comments as List).length;
        postMap['is_liked'] = isLiked;
        enrichedPosts.add(postMap);
      } catch (e) {
        enrichedPosts.add(_cleanMap(post));
      }
    }
    return enrichedPosts;
  }

  Future<Map<String, dynamic>?> getPostDetails(String postId) async {
    try {
      final res = await _supabase
          .from('posts')
          .select('*, profiles(username, display_name, avatar_url, is_verified)')
          .eq('id', postId)
          .single();
      
      final resMap = _cleanMap(res);
      final likesRes = await _supabase.from('post_likes').select('user_id').eq('post_id', postId);
      final commentsRes = await _supabase.from('comments').select('id').eq('post_id', postId);
      
      final currentUserId = _supabase.auth.currentUser?.id;
      bool isLiked = false;
      if (currentUserId != null) {
        final isLikedRes = await _supabase.from('post_likes').select().eq('post_id', postId).eq('user_id', currentUserId).maybeSingle();
        isLiked = isLikedRes != null;
      }

      resMap['likes_count'] = (likesRes as List).length;
      resMap['comments_count'] = (commentsRes as List).length;
      resMap['is_liked'] = isLiked;
      return resMap;
    } catch (e) { return null; }
  }

  Future<bool> toggleLike(String postId, bool isCurrentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      if (isCurrentlyLiked) {
        await _supabase.from('post_likes').delete().eq('post_id', postId).eq('user_id', userId);
      } else {
        await _supabase.from('post_likes').insert({'post_id': postId, 'user_id': userId});
      }
      return true;
    } catch (e) { return false; }
  }

  Future<bool> toggleCommentLike(String commentId, bool isCurrentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      if (isCurrentlyLiked) {
        await _supabase.from('comment_likes').delete().eq('comment_id', commentId).eq('user_id', userId);
      } else {
        await _supabase.from('comment_likes').insert({'comment_id': commentId, 'user_id': userId});
      }
      return true;
    } catch (e) { return false; }
  }

  Future<List<dynamic>> getComments(String postId) async {
    try {
      final hiddenWords = await _getHiddenWords();
      final res = await _supabase
          .from('comments')
          .select('*, profiles(username, avatar_url, is_verified)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      
      final List<dynamic> enrichedComments = [];
      final currentUserId = _supabase.auth.currentUser?.id;

      for (var comment in res as List) {
        // Filtrar comentarios por palabras ocultas
        if (_shouldFilter(comment['content'] ?? '', hiddenWords)) continue;

        final commentMap = _cleanMap(comment);
        final likes = await _supabase.from('comment_likes').select('user_id').eq('comment_id', commentMap['id']);
        bool likedByMe = false;
        if (currentUserId != null) {
          final myLike = await _supabase.from('comment_likes').select().eq('comment_id', commentMap['id']).eq('user_id', currentUserId).maybeSingle();
          likedByMe = myLike != null;
        }
        commentMap['likes_count'] = (likes as List).length;
        commentMap['is_liked'] = likedByMe;
        enrichedComments.add(commentMap);
      }
      return enrichedComments;
    } catch (e) { return []; }
  }

  Future<bool> addComment(String postId, String content, {String? parentId, String? replyToUsername}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'parent_id': parentId,
        'reply_to_username': replyToUsername,
      });
      return true;
    } catch (e) { return false; }
  }

  Future<List<Map<String, dynamic>>> attachProfiles(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    try {
      final List<String> userIds = posts.map((p) => p['user_id'] as String).toSet().toList();
      final profilesData = await _supabase.from('profiles').select('id, username, display_name, avatar_url, is_verified').inFilter('id', userIds);
      final Map<String, dynamic> profilesMap = {for (var p in profilesData) p['id']: p};
      return posts.map((post) => {...post, 'profiles': profilesMap[post['user_id']]}).toList();
    } catch (e) { return posts; }
  }

  Future<List<dynamic>> getGlobalPosts({String? query}) async {
    try {
      final hiddenWords = await _getHiddenWords();
      var request = _supabase.from('posts').select('*, profiles(username, display_name, avatar_url, is_verified)');
      if (query != null && query.isNotEmpty) request = request.ilike('content', '%$query%');
      final posts = await request.order('created_at', ascending: false).limit(40);
      
      // Filtrado por palabras ocultas en global
      final filtered = List<Map<String, dynamic>>.from(posts).where((post) {
        return !_shouldFilter(post['content'] ?? '', hiddenWords);
      }).take(20).toList();

      return await _attachCounts(filtered);
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getUserPosts(String userId) async {
    try {
      final posts = await _supabase.from('posts').select('*').eq('user_id', userId).order('created_at', ascending: false);
      return await _attachCounts(List<Map<String, dynamic>>.from(posts));
    } catch (e) { return []; }
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
    } catch (e) { return false; }
  }
}
