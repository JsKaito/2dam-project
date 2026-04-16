import 'dart:io';
import 'dart:convert';
import 'dart:html' as html; // Solo para Web
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService {
  final _supabase = Supabase.instance.client;

  Stream<Map<String, dynamic>> get profileStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
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
      return await _supabase.from('profiles').select('*').eq('id', user.id).single();
    } catch (e) {
      return null;
    }
  }

  // --- 1. ELIMINACIÓN REAL ---
  Future<bool> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
      return true;
    } catch (e) {
      print("Error fatal al eliminar cuenta: $e");
      return false;
    }
  }

  // --- 2. VERIFICACIÓN 2 PASOS (MFA REAL) ---
  Future<String?> enrollMFA() async {
    try {
      final res = await _supabase.auth.mfa.enroll(factorType: FactorType.totp);
      return res.totp?.qrCode;
    } catch (e) {
      print("Error MFA: $e");
      return null;
    }
  }

  // --- 3. SEGURIDAD Y PASSWORD ---
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logoutOthers() async {
    await _supabase.auth.signOut(scope: SignOutScope.others);
  }

  // --- 4. VERIFICACIÓN DE CUENTA ---
  Future<bool> requestVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      await _supabase.from('verification_requests').insert({'user_id': user.id});
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- 5. DESCARGA REAL DE DATOS (JSON) ---
  Future<void> downloadUserDataReal() async {
    try {
      final user = _supabase.auth.currentUser;
      final profile = await getCurrentProfile();
      final Map<String, dynamic> data = {
        "account": {"id": user?.id, "email": user?.email},
        "profile": profile,
      };
      if (kIsWeb) {
        final bytes = utf8.encode(jsonEncode(data));
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)..setAttribute("download", "data_artists_cottage.json")..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) { print("Error descarga: $e"); }
  }

  // --- 6. GESTIÓN DE AJUSTES ---
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      await _supabase.from('profiles').update({key: value}).eq('id', user.id);
      return true;
    } catch (e) { return false; }
  }

  // --- 7. PERFIL Y AVATAR ---
  Future<String?> uploadAvatar(dynamic imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final path = 'avatars/${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (kIsWeb) {
        await _supabase.storage.from('posts').uploadBinary(path, imageFile);
      } else {
        await _supabase.storage.from('posts').upload(path, imageFile as File);
      }
      return _supabase.storage.from('posts').getPublicUrl(path);
    } catch (e) { return null; }
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
      final Map<String, dynamic> updates = {
        if (username.isNotEmpty) 'username': username,
        if (displayName.isNotEmpty) 'display_name': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
      await _supabase.from('profiles').update(updates).eq('id', user.id);
      return true;
    } catch (e) { return false; }
  }

  Future<List<dynamic>> getBlockedUsers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      return await _supabase.from('blocked_users').select('*, profiles!blocked_id(username)').eq('blocker_id', user.id);
    } catch (e) { return []; }
  }
}
