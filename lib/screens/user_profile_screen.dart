import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;
  final String? username;
  
  const UserProfileScreen({super.key, this.userId, this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();
  
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isMe = false;
  Map<String, dynamic>? _profile;
  List<dynamic> _posts = [];
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Map<String, dynamic>? profile;
    
    // Obtenemos el perfil por ID o por Username (@)
    if (widget.userId != null) {
      profile = await _profileService.getProfileById(widget.userId!);
    } else if (widget.username != null) {
      profile = await _profileService.getProfileByUsername(widget.username!);
    }

    if (profile == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final String userId = profile['id'];
    
    // Verificamos si soy yo
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _isMe = currentUserId == userId;

    final results = await Future.wait([
      _profileService.isFollowing(userId),
      _postService.getUserPosts(userId),
      _profileService.getFollowCounts(userId),
    ]);

    if (mounted) {
      setState(() {
        _profile = profile;
        _isFollowing = results[0] as bool;
        _posts = results[1] as List<dynamic>;
        final counts = results[2] as Map<String, int>;
        _followersCount = counts['followers'] ?? 0;
        _followingCount = counts['following'] ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isMe) return;
    
    final String userId = _profile!['id'];
    if (_isFollowing) {
      await _profileService.unfollowUser(userId);
      setState(() {
        _isFollowing = false;
        _followersCount--;
      });
    } else {
      await _profileService.followUser(userId);
      setState(() {
        _isFollowing = true;
        _followersCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
    if (_profile == null) return const Scaffold(body: Center(child: Text("Usuario no encontrado")));

    final displayName = _profile!['display_name'] ?? _profile!['username'] ?? "Artista";

    return Scaffold(
      appBar: AppBar(
        title: Text("@${_profile!['username']}", style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isMe) IconButton(icon: const Icon(Icons.more_vert), onPressed: _showMoreOptions),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(_profile!['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn("Posts", _posts.length.toString()),
                        _buildStatColumn("Seguidores", _followersCount.toString()),
                        _buildStatColumn("Siguiendo", _followingCount.toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_profile!['bio'] ?? "Artista en Artist's Cottage ✨", style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isMe 
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? const Color(0xFF1E1E1E) : const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(_isFollowing ? "Siguiendo" : "Seguir", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {}, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("Mensaje", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Image.network(post['image_url'], fit: BoxFit.cover);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: const Text("Bloquear usuario", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              _profileService.blockUser(_profile!['id']);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario bloqueado")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: const Text("Reportar usuario"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
