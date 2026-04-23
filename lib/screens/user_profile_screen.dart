import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_alley/services/profile_service.dart';
import 'package:artists_alley/services/post_service.dart';
import 'package:artists_alley/navigation_wrapper.dart';
import 'package:artists_alley/screens/post_details_screen.dart';

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
  bool _isMe = false;
  Map<String, dynamic>? _profile;
  List<dynamic> _posts = [];
  int _followersCount = 0;
  int _followingCount = 0;

  late Future<void> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadAllProfileData();
  }

  Future<void> _loadAllProfileData() async {
    Map<String, dynamic>? profile;
    
    if (widget.userId != null) {
      profile = await _profileService.getProfileById(widget.userId!);
    } else if (widget.username != null) {
      profile = await _profileService.getProfileByUsername(widget.username!);
    }

    if (profile == null) throw Exception("Usuario no encontrado");

    final String targetId = profile['id'];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _isMe = currentUserId == targetId;

    // Si soy YO, redirigimos a la pestaña de perfil real para mantener la navegación coherente
    if (_isMe && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationWrapper.navigationKey.currentState?.setIndex(4);
        Navigator.pop(context); // Cerramos el perfil "falso"
      });
      return;
    }

    final results = await Future.wait([
      _profileService.isFollowing(targetId),
      _profileService.getFollowCounts(targetId),
      _postService.getUserPostsStream(targetId).first, 
    ]);

    _profile = profile;
    _isFollowing = results[0] as bool;
    final counts = results[1] as Map<String, int>;
    _followersCount = counts['followers'] ?? 0;
    _followingCount = counts['following'] ?? 0;
    _posts = results[2] as List<dynamic>;
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    final String targetId = _profile!['id'];

    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });

    try {
      if (!_isFollowing) {
        await _profileService.unfollowUser(targetId);
      } else {
        await _profileService.followUser(targetId);
      }
    } catch (e) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al procesar seguimiento")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
        }

        if (snapshot.hasError || _profile == null) {
          if (_isMe) return const SizedBox.shrink(); // Evitamos flash de error si redirigimos
          return const Scaffold(body: Center(child: Text("Error al cargar el perfil")));
        }

        final displayName = _profile!['display_name'] ?? _profile!['username'] ?? "Artista";
        final isVerified = _profile!['is_verified'] ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text("@${_profile!['username']}", style: TextStyle(fontSize: 16, color: theme.textTheme.titleLarge?.color)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: theme.appBarTheme.iconTheme,
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
                        backgroundColor: theme.brightness == Brightness.dark ? Colors.white24 : Colors.grey[200],
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
                        Row(
                          children: [
                            Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.titleLarge?.color)),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profile!['bio'] ?? "Artista en Artist's Cottage ✨", 
                          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleFollow, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing 
                              ? (theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200]) 
                              : const Color(0xFF6C63FF),
                            foregroundColor: _isFollowing 
                              ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) 
                              : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(_isFollowing ? "Siguiendo" : "Seguir", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(height: 1, thickness: 1, color: theme.dividerColor),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => PostDetailsScreen(postId: post['id'].toString()))
                      ),
                      child: Image.network(post['image_url'], fit: BoxFit.cover),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
