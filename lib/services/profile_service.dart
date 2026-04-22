import 'dart:io';
import 'dart:convert';
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService {
  final _supabase = Supabase.instance.client;

  static const String defaultAvatarUrl = 'https://yrbzkgfomjqilmyxzfqe.supabase.co/storage/v1/object/public/default/default_pfp.webp';
  static const String defaultBannerUrl = 'https://yrbzkgfomjqilmyxzfqe.supabase.co/storage/v1/object/public/default/default_banner.jpg';

  // --- STREAMS EN TIEMPO REAL ---

  Stream<Map<String, dynamic>> get profileStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((event) => event.isNotEmpty ? Map<String, dynamic>.from(event.first) : {});
  }

  Stream<Map<String, dynamic>> getProfileStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => event.isNotEmpty ? Map<String, dynamic>.from(event.first) : {});
  }

  Stream<Map<String, int>> getFollowCountsStream(String userId) {
    return _supabase
        .from('followers')
        .stream(primaryKey: ['follower_id', 'following_id'])
        .map((event) {
          final followers = event.where((f) => f['following_id'] == userId).length;
          final following = event.where((f) => f['follower_id'] == userId).length;
          return {'followers': followers, 'following': following};
        });
  }

  // --- MÉTODOS DE CONSULTA ÚNICA (RESTAURADOS) ---

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final res = await _supabase.from('profiles').select('*').eq('id', user.id).single();
      return Map<String, dynamic>.from(res);
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final res = await _supabase.from('profiles').select('*').eq('id', userId).single();
      return Map<String, dynamic>.from(res);
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    try {
      final res = await _supabase.from('profiles').select('*').ilike('username', username.trim()).maybeSingle();
      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final followers = await _supabase.from('followers').select('follower_id').eq('following_id', userId);
      final following = await _supabase.from('followers').select('following_id').eq('follower_id', userId);
      return {'followers': (followers as List).length, 'following': (following as List).length};
    } catch (e) { return {'followers': 0, 'following': 0}; }
  }

  Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return true;
    try {
      final res = await _supabase.from('profiles').select('username').ilike('username', username.trim()).maybeSingle();
      return res == null;
    } catch (e) { return false; }
  }

  // --- ACCIONES DE PERFIL ---

  Future<String?> uploadBanner(dynamic imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final path = 'banners/${user.id}/banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (kIsWeb) await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      else await _supabase.storage.from('posts').upload(path, imageFile as File);
      final url = _supabase.storage.from('posts').getPublicUrl(path);
      await _supabase.from('profiles').update({'banner_url': url}).eq('id', user.id);
      return url;
    } catch (e) { return null; }
  }

  Future<String?> uploadAvatar(dynamic imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final path = 'avatars/${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (kIsWeb) await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      else await _supabase.storage.from('posts').upload(path, imageFile as File);
      final url = _supabase.storage.from('posts').getPublicUrl(path);
      await _supabase.from('profiles').update({'avatar_url': url}).eq('id', user.id);
      return url;
    } catch (e) { return null; }
  }

  Future<bool> updateProfile({required String username, required String displayName, String? bio, String? avatarUrl, String? bannerUrl}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final Map<String, dynamic> updates = {
        if (username.isNotEmpty) 'username': username.toLowerCase(), 
        if (displayName.isNotEmpty) 'display_name': displayName, 
        if (bio != null) 'bio': bio, 
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl
      };
      await _supabase.from('profiles').update(updates).eq('id', user.id);
      return true;
    } catch (e) { return false; }
  }

  // --- LÓGICA SOCIAL Y SEGURIDAD ---

  Future<List<dynamic>> searchUsers(String query) async {
    try {
      var request = _supabase.from('profiles').select('id, username, display_name, avatar_url, bio, is_verified, banner_url');
      if (query.isNotEmpty) request = request.or('username.ilike.%$query%,display_name.ilike.%$query%');
      final res = await request.limit(20);
      return List.from(res as List);
    } catch (e) { return []; }
  }

  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;
      final res = await _supabase.from('followers').select().eq('follower_id', currentUserId).eq('following_id', targetUserId).maybeSingle();
      return res != null;
    } catch (e) { return false; }
  }

  Future<void> followUser(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    await _supabase.from('followers').insert({'follower_id': currentUserId, 'following_id': targetUserId});
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    await _supabase.from('followers').delete().eq('follower_id', currentUserId).eq('following_id', targetUserId);
  }

  Future<bool> sendPasswordResetEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) return false;
      await _supabase.auth.resetPasswordForEmail(user!.email!);
      return true;
    } catch (e) { return false; }
  }

  Future<void> downloadUserDataReal() async {
    try {
      final user = _supabase.auth.currentUser;
      final profile = await getCurrentProfile();
      final Map<String, dynamic> data = {"account": {"id": user?.id, "email": user?.email}, "profile": profile};
      if (kIsWeb) {
        final bytes = utf8.encode(jsonEncode(data));
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)..setAttribute("download", "data.json")..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {}
  }

  Future<String?> getVerificationStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final res = await _supabase.from('verification_requests').select('status').eq('user_id', user.id).maybeSingle();
      return res?['status'];
    } catch (e) { return null; }
  }

  Future<bool> requestVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final existing = await getVerificationStatus();
      if (existing == 'accepted' || existing == 'pending') return false;
      if (existing == 'denied') await _supabase.from('verification_requests').delete().eq('user_id', user.id);
      await _supabase.from('verification_requests').insert({'user_id': user.id, 'status': 'pending'});
      return true;
    } catch (e) { return false; }
  }

  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      await _supabase.from('profiles').update({key: value}).eq('id', _supabase.auth.currentUser!.id);
      return true;
    } catch (e) { return false; }
  }

  Future<void> logoutOthers() async {
    await _supabase.auth.signOut(scope: SignOutScope.others);
  }

  Future<bool> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
      return true;
    } catch (e) { return false; }
  }
}
