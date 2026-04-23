import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_alley/services/profile_service.dart';

class UserListScreen extends StatefulWidget {
  final String userId;
  final String title;
  final String type; // 'followers' or 'following'

  const UserListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.type,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ProfileService _profileService = ProfileService();
  final _supabase = Supabase.instance.client;
  
  List<dynamic> _mutuals = [];
  List<dynamic> _others = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      
      final res = await _supabase.rpc('get_user_connections', params: {
        'target_id': widget.userId,
        'conn_type': widget.type,
        'viewer_id': currentUserId,
      });

      final List<dynamic> allUsers = List.from(res);
      
      if (mounted) {
        setState(() {
          _mutuals = allUsers.where((u) => u['is_mutual'] == true).toList();
          _others = allUsers.where((u) => u['is_mutual'] != true).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(dynamic user) async {
    final bool isCurrentlyFollowing = user['viewer_is_following'] ?? false;
    final String targetId = user['id'];

    setState(() {
      user['viewer_is_following'] = !isCurrentlyFollowing;
    });

    try {
      if (isCurrentlyFollowing) {
        await _profileService.unfollowUser(targetId);
      } else {
        await _profileService.followUser(targetId);
      }
    } catch (e) {
      setState(() {
        user['viewer_is_following'] = isCurrentlyFollowing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : (_mutuals.isEmpty && _others.isEmpty)
              ? Center(child: Text("No hay usuarios que mostrar", style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
              : ListView(
                  children: [
                    if (_mutuals.isNotEmpty) ...[
                      _buildHeader("Mutuos"),
                      ..._mutuals.map((u) => _buildUserTile(u)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 32),
                      ),
                    ],
                    if (_others.isNotEmpty) ...[
                      if (_mutuals.isNotEmpty) _buildHeader("Otros usuarios"),
                      ..._others.map((u) => _buildUserTile(u)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserTile(dynamic user) {
    final theme = Theme.of(context);
    final bool isMe = _supabase.auth.currentUser?.id == user['id'];
    final bool isFollowing = user['viewer_is_following'] ?? false;

    return ListTile(
      leading: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/user/${user['username']}'),
        child: CircleAvatar(
          backgroundImage: NetworkImage(user['avatar_url'] ?? ProfileService.defaultAvatarUrl),
        ),
      ),
      title: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/user/${user['username']}'),
        child: Row(
          children: [
            Flexible(
              child: Text(
                user['display_name'] ?? user['username'],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.textTheme.titleMedium?.color, fontWeight: FontWeight.bold),
              ),
            ),
            if (user['is_verified'] == true) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
          ],
        ),
      ),
      subtitle: Text("@${user['username']}", style: const TextStyle(color: Colors.grey)),
      trailing: isMe 
        ? null 
        : SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () => _toggleFollow(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.transparent : const Color(0xFF6C63FF),
                foregroundColor: isFollowing ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) : Colors.white,
                elevation: 0,
                side: isFollowing ? const BorderSide(color: Colors.grey) : null,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                isFollowing ? "Siguiendo" : "Seguir",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
    );
  }
}
