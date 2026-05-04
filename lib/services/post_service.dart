import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostService {
  // Patrón Singleton para manejar suscripciones en tiempo real centralizadas
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  PostService._internal() {
    _initRealtime();
  }

  final _supabase = Supabase.instance.client;

  // Transmisión de eventos de actualización de posts (para sincronización entre pantallas)
  final _postUpdateController = StreamController<String>.broadcast();
  Stream<String> get postUpdateStream => _postUpdateController.stream;

  void _initRealtime() {
    // Escuchar cambios en la tabla 'post_likes' para actualizaciones en tiempo real de otros usuarios
    _supabase.channel('public:post_likes').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'post_likes',
      callback: (payload) {
        final record = (payload.newRecord.isEmpty) ? payload.oldRecord : payload.newRecord;
        final postId = record['post_id']?.toString();
        if (postId != null) {
          _postUpdateController.add(postId);
        }
      },
    ).subscribe();
  }

  void notifyPostUpdate(String postId) {
    _postUpdateController.add(postId);
  }

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

  // --- STREAMS OPTIMIZADOS ---

  Stream<List<Map<String, dynamic>>> getHomeFeedStream(String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((allPosts) async {
          final results = await Future.wait<dynamic>([
            _getHiddenWords(),
            _supabase.from('followers').select('following_id').eq('follower_id', userId),
          ]);

          final hiddenWords = results[0] as List<String>;
          final followingData = results[1] as List;
          final followingIds = followingData.map((f) => f['following_id'] as String).toList();
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
          final currentUserId = _supabase.auth.currentUser?.id;
          final hiddenWords = await _getHiddenWords();
          
          List<String> followingIds = [];
          if (currentUserId != null) {
            final followingData = await _supabase.from('followers').select('following_id').eq('follower_id', currentUserId);
            followingIds = (followingData as List).map((f) => f['following_id'] as String).toList();
            followingIds.add(currentUserId);
          }

          final List<Map<String, dynamic>> initialCandidates = [];
          for (var post in allPosts) {
            final text = "${post['title'] ?? ''} ${post['content'] ?? ''}";
            if (!_shouldFilter(text, hiddenWords)) {
              initialCandidates.add(Map<String, dynamic>.from(post));
            }
            if (initialCandidates.length >= 60) break;
          }

          if (initialCandidates.isEmpty) return [];

          final authorIds = initialCandidates.map((p) => p['user_id'] as String).toSet().toList();
          final profilesData = await _supabase.from('profiles').select('id, is_private').inFilter('id', authorIds);
          final privacyMap = {for (var p in profilesData) p['id']: p['is_private'] ?? false};

          final List<Map<String, dynamic>> finalPosts = [];
          for (var post in initialCandidates) {
            final bool isPrivate = privacyMap[post['user_id']] ?? false;
            if (!isPrivate || followingIds.contains(post['user_id'])) {
              finalPosts.add(post);
            }
            if (finalPosts.length >= 30) break;
          }

          return await _attachCounts(finalPosts);
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

  // --- LÓGICA DE CARGA MASIVA (SIN N+1) ---

  Future<List<Map<String, dynamic>>> _attachCounts(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return [];
    final currentUserId = _supabase.auth.currentUser?.id;
    
    final postIds = posts.map((p) => p['id']).toList();
    final userIds = posts.map((p) => p['user_id'] as String).toSet().toList();

    final results = await Future.wait<dynamic>([
      _supabase.from('profiles').select('id, username, display_name, avatar_url, is_verified, is_private').inFilter('id', userIds),
      if (currentUserId != null) 
        _supabase.from('post_likes').select('post_id').eq('user_id', currentUserId).inFilter('post_id', postIds)
      else 
        Future.value([]),
      _supabase.from('post_likes').select('post_id').inFilter('post_id', postIds),
      _supabase.from('comments').select('post_id').inFilter('post_id', postIds),
    ]);

    final profilesMap = {for (var p in results[0] as List) p['id']: _deepClean(p)};
    final myLikes = (results[1] as List).map((l) => l['post_id']).toSet();
    
    final likesCountMap = <dynamic, int>{};
    for (var l in results[2] as List) {
      final pid = l['post_id'];
      likesCountMap[pid] = (likesCountMap[pid] ?? 0) + 1;
    }

    final commentsCountMap = <dynamic, int>{};
    for (var c in results[3] as List) {
      final pid = c['post_id'];
      commentsCountMap[pid] = (commentsCountMap[pid] ?? 0) + 1;
    }

    return posts.map((post) {
      final pid = post['id'];
      final p = Map<String, dynamic>.from(post);
      p['likes_count'] = likesCountMap[pid] ?? 0;
      p['comments_count'] = commentsCountMap[pid] ?? 0;
      p['profiles'] = profilesMap[p['user_id']];
      p['is_liked'] = myLikes.contains(pid);
      return p;
    }).toList();
  }

  // --- DETALLES Y COMENTARIOS ---

  Future<Map<String, dynamic>?> getPostDetails(String postId) async {
    try {
      final id = _formatId(postId);
      final currentUserId = _supabase.auth.currentUser?.id;

      final results = await Future.wait<dynamic>([
        _supabase.from('posts').select('*, profiles(*)').eq('id', id).single(),
        _supabase.from('post_likes').select('user_id').eq('post_id', id),
        _supabase.from('comments').select('id').eq('post_id', id),
        if (currentUserId != null)
          _supabase.from('post_likes').select().eq('post_id', id).eq('user_id', currentUserId).maybeSingle()
        else
          Future.value(null),
      ]);

      final resMap = _deepClean(results[0]);
      resMap['likes_count'] = (results[1] as List).length;
      resMap['comments_count'] = (results[2] as List).length;
      resMap['is_liked'] = results[3] != null;
      
      return resMap;
    } catch (e) { return null; }
  }

  Future<List<dynamic>> getComments(String postId) async {
    try {
      final id = _formatId(postId);
      final currentUserId = _supabase.auth.currentUser?.id;

      final results = await Future.wait<dynamic>([
        _getHiddenWords(),
        _supabase.from('comments').select('*, profiles(*)').eq('post_id', id).order('created_at', ascending: true),
      ]);
      
      final hiddenWords = results[0] as List<String>;
      final rawComments = results[1] as List;
      if (rawComments.isEmpty) return [];

      final commentIds = rawComments.map((c) => c['id']).toList();
      
      final batchResults = await Future.wait<dynamic>([
        _supabase.from('comment_likes').select('comment_id').inFilter('comment_id', commentIds),
        if (currentUserId != null)
          _supabase.from('comment_likes').select('comment_id').eq('user_id', currentUserId).inFilter('comment_id', commentIds)
        else
          Future.value([]),
      ]);

      final allLikes = batchResults[0] as List;
      final myLikes = (batchResults[1] as List).map((l) => l['comment_id']).toSet();

      final likesCountMap = <dynamic, int>{};
      for (var l in allLikes) {
        final cid = l['comment_id'];
        likesCountMap[cid] = (likesCountMap[cid] ?? 0) + 1;
      }

      final List<dynamic> enriched = [];
      for (var comment in rawComments) {
        if (_shouldFilter(comment['content'] ?? '', hiddenWords)) continue;
        
        final commentMap = _deepClean(comment);
        final cid = comment['id'];
        commentMap['likes_count'] = likesCountMap[cid] ?? 0;
        commentMap['is_liked'] = myLikes.contains(cid);
        enriched.add(commentMap);
      }
      return enriched;
    } catch (e) { return []; }
  }

  // --- ACCIONES ---

  Future<bool> deletePost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      await _supabase.from('posts').delete().eq('id', _formatId(postId)).eq('user_id', userId);
      return true;
    } catch (e) { return false; }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      await _supabase.from('comments').delete().eq('id', _formatId(commentId)).eq('user_id', userId);
      return true;
    } catch (e) { return false; }
  }

  Future<bool> toggleLike(String postId, bool isCurrentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final id = _formatId(postId);
      
      final existing = await _supabase.from('post_likes').select().eq('post_id', id).eq('user_id', userId).maybeSingle();
      if (existing != null) {
        await _supabase.from('post_likes').delete().eq('post_id', id).eq('user_id', userId);
      } else {
        await _supabase.from('post_likes').insert({'post_id': id, 'user_id': userId});
      }
      
      // Notificar localmente para sincronización instantánea entre widgets
      _postUpdateController.add(postId);
      
      return true;
    } catch (e) { 
      if (e.toString().contains('23505')) {
        _postUpdateController.add(postId);
        return true;
      }
      return false;
    }
  }

  Future<bool> toggleCommentLike(String commentId, bool isCurrentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final id = _formatId(commentId);
      
      final existing = await _supabase.from('comment_likes').select().eq('comment_id', id).eq('user_id', userId).maybeSingle();
      if (existing != null) {
        await _supabase.from('comment_likes').delete().eq('comment_id', id).eq('user_id', userId);
      } else {
        await _supabase.from('comment_likes').insert({'comment_id': id, 'user_id': userId});
      }
      return true;
    } catch (e) { return e.toString().contains('23505'); }
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
    } catch (e) { return false; }
  }
}
