import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  final _supabase = Supabase.instance.client;

  dynamic _deepClean(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return Map<String, dynamic>.from(data.map((key, value) => MapEntry(key.toString(), _deepClean(value))));
    }
    if (data is List) {
      return data.map((item) => _deepClean(item)).toList();
    }
    return data;
  }

  dynamic _formatId(String id) => int.tryParse(id) ?? id;

  Future<List<String>> _getHiddenWords() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await _supabase.from('profiles').select('hidden_words').eq('id', userId).maybeSingle();
      final String words = res?['hidden_words'] ?? '';
      return words.split(',').map((w) => w.trim().toLowerCase()).where((w) => w.isNotEmpty).toList();
    } catch (e) { return []; }
  }

  bool _shouldFilter(String content, List<String> hiddenWords) {
    if (content.isEmpty || hiddenWords.isEmpty) return false;
    final lowerContent = content.toLowerCase();
    for (var word in hiddenWords) {
      if (lowerContent.contains(word)) return true;
    }
    return false;
  }

  // --- STREAMS EN TIEMPO REAL ---

  Stream<List<Map<String, dynamic>>> getHomeFeedStream(String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((allPosts) async {
          final hiddenWords = await _getHiddenWords();
          final followingData = await _supabase.from('followers').select('following_id').eq('follower_id', userId);
          final followingIds = (followingData as List).map((f) => f['following_id'] as String).toList();
          followingIds.add(userId);

          final filteredPosts = allPosts.where((post) {
            final searchableText = "${post['title'] ?? ''} ${post['content'] ?? ''} ${post['author_name'] ?? ''}";
            return followingIds.contains(post['user_id']) && !_shouldFilter(searchableText, hiddenWords);
          }).toList();

          return await _attachCounts(filteredPosts.map((p) => Map<String, dynamic>.from(p)).toList());
        });
  }

  Stream<List<Map<String, dynamic>>> getGlobalPostsStream() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((allPosts) async {
          final hiddenWords = await _getHiddenWords();
          final filtered = allPosts.where((post) {
            final searchableText = "${post['title'] ?? ''} ${post['content'] ?? ''} ${post['author_name'] ?? ''}";
            return !_shouldFilter(searchableText, hiddenWords);
          }).take(30).toList();
          return await _attachCounts(filtered.map((p) => Map<String, dynamic>.from(p)).toList());
        });
  }

  Stream<List<Map<String, dynamic>>> getUserPostsStream(String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((posts) async => await _attachCounts(posts.map((p) => Map<String, dynamic>.from(p)).toList()));
  }

  Future<List<Map<String, dynamic>>> _attachCounts(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    final currentUserId = _supabase.auth.currentUser?.id;
    final List<Map<String, dynamic>> enrichedPosts = [];
    
    for (var post in posts) {
      try {
        final originalId = post['id'];
        final p = Map<String, dynamic>.from(post);
        final likesRes = await _supabase.from('post_likes').select('user_id').eq('post_id', originalId);
        final commentsRes = await _supabase.from('comments').select('id').eq('post_id', originalId);
        
        final profile = await _supabase.from('profiles').select('username, display_name, avatar_url, is_verified').eq('id', p['user_id']).single();
        
        p['likes_count'] = (likesRes as List).length;
        p['comments_count'] = (commentsRes as List).length;
        p['profiles'] = _deepClean(profile);
        
        if (currentUserId != null) {
          final myLike = await _supabase.from('post_likes').select().eq('post_id', originalId).eq('user_id', currentUserId).maybeSingle();
          p['is_liked'] = myLike != null;
        }
        enrichedPosts.add(p);
      } catch (e) { enrichedPosts.add(post); }
    }
    return enrichedPosts;
  }

  // --- DETALLES Y COMENTARIOS ---

  Future<Map<String, dynamic>?> getPostDetails(String postId) async {
    try {
      final id = _formatId(postId);
      final res = await _supabase.from('posts').select('*, profiles(*)').eq('id', id).single();
      final resMap = _deepClean(res);
      
      final likesRes = await _supabase.from('post_likes').select('user_id').eq('post_id', id);
      final commentsRes = await _supabase.from('comments').select('id').eq('post_id', id);
      
      final currentUserId = _supabase.auth.currentUser?.id;
      bool isLiked = false;
      if (currentUserId != null) {
        final isLikedRes = await _supabase.from('post_likes').select().eq('post_id', id).eq('user_id', currentUserId).maybeSingle();
        isLiked = isLikedRes != null;
      }

      resMap['likes_count'] = (likesRes as List).length;
      resMap['comments_count'] = (commentsRes as List).length;
      resMap['is_liked'] = isLiked;
      return resMap;
    } catch (e) { return null; }
  }

  Future<List<dynamic>> getComments(String postId) async {
    try {
      final hiddenWords = await _getHiddenWords();
      final res = await _supabase.from('comments').select('*, profiles(*)').eq('post_id', _formatId(postId)).order('created_at', ascending: true);
      
      final List<dynamic> enrichedComments = [];
      final currentUserId = _supabase.auth.currentUser?.id;

      for (var comment in res as List) {
        if (_shouldFilter(comment['content'] ?? '', hiddenWords)) continue;
        
        final originalId = comment['id'];
        final commentMap = _deepClean(comment);
        final likesRes = await _supabase.from('comment_likes').select('user_id').eq('comment_id', originalId);
        
        if (currentUserId != null) {
          final myLike = await _supabase.from('comment_likes').select().eq('comment_id', originalId).eq('user_id', currentUserId).maybeSingle();
          commentMap['is_liked'] = myLike != null;
        }
        commentMap['likes_count'] = (likesRes as List).length;
        enrichedComments.add(commentMap);
      }
      return enrichedComments;
    } catch (e) { return []; }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      await _supabase.from('posts').delete().eq('id', _formatId(postId)).eq('user_id', userId);
      return true;
    } catch (e) { return false; }
  }

  // --- LÓGICA SOCIAL REFORZADA ---

  Future<bool> toggleLike(String postId, bool isCurrentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final id = _formatId(postId);
      
      // Consultamos el estado real para evitar conflictos
      final existing = await _supabase.from('post_likes').select().eq('post_id', id).eq('user_id', userId).maybeSingle();

      if (existing != null) {
        await _supabase.from('post_likes').delete().eq('post_id', id).eq('user_id', userId);
      } else {
        await _supabase.from('post_likes').insert({'post_id': id, 'user_id': userId});
      }
      return true;
    } catch (e) { 
      if (e.toString().contains('23505') || e.toString().contains('409')) return true;
      return false; 
    }
  }

  Future<bool> toggleCommentLike(String commentId, bool isCurrentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final id = _formatId(commentId);
      
      // Lógica de "Autocuración": Verificamos el estado real en la DB
      final existing = await _supabase
          .from('comment_likes')
          .select()
          .eq('comment_id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Si el like existe en DB, lo borramos
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', id)
            .eq('user_id', userId);
      } else {
        // Si no existe, lo creamos
        await _supabase
            .from('comment_likes')
            .insert({'comment_id': id, 'user_id': userId});
      }
      return true;
    } catch (e) { 
      // Manejo de carrera: si otro proceso insertó mientras comprobábamos, lo damos por bueno
      if (e.toString().contains('23505') || e.toString().contains('409')) return true;
      print("Error real en toggleCommentLike: $e");
      return false; 
    }
  }

  Future<bool> addComment(String postId, String content, {String? parentId, String? replyToUsername}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      await _supabase.from('comments').insert({
        'post_id': _formatId(postId), 
        'user_id': userId, 
        'content': content, 
        'parent_id': parentId, 
        'reply_to_username': replyToUsername
      });
      return true;
    } catch (e) { return false; }
  }

  // --- OTROS MÉTODOS ---

  Future<List<Map<String, dynamic>>> attachProfiles(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    try {
      final List<String> userIds = posts.map((p) => p['user_id'] as String).toSet().toList();
      final profilesData = await _supabase.from('profiles').select('id, username, display_name, avatar_url, is_verified').inFilter('id', userIds);
      final Map<String, dynamic> profilesMap = {for (var p in profilesData) p['id']: _deepClean(p)};
      return posts.map((post) => {...post, 'profiles': profilesMap[post['user_id']]}).toList();
    } catch (e) { return posts; }
  }

  Future<bool> createPost({
    required String title,
    String? description,
    required dynamic imageFile,
    String? author,
    String? captureDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';
      
      if (kIsWeb) await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      else await _supabase.storage.from('posts').upload(path, imageFile as File);
      
      final imageUrl = _supabase.storage.from('posts').getPublicUrl(path);
      
      await _supabase.from('posts').insert({
        'user_id': user.id, 
        'title': title,
        'content': description ?? '',
        'image_url': imageUrl,
        'author_name': author ?? 'Artista',
        'capture_date': captureDate,
      });
      return true;
    } catch (e) { 
      print("Error creating post: $e");
      return false; 
    }
  }
}
