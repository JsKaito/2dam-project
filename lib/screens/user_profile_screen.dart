import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_cottage/services/profile_service.dart';
import 'package:artists_cottage/services/post_service.dart';
import 'package:artists_cottage/services/shortcode_utils.dart';
import 'package:artists_cottage/screens/user_list_screen.dart';

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
  String? _requestStatus;
  bool _isMe = false;
  Map<String, dynamic>? _profile;
  int _followersCount = 0;
  int _followingCount = 0;

  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    Map<String, dynamic>? profile;
    
    if (widget.userId != null) {
      profile = await _profileService.getProfileById(widget.userId!);
    } else if (widget.username != null) {
      profile = await _profileService.getProfileByUsername(widget.username!);
    }

    if (profile == null) return;

    final String targetId = profile['id'];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _isMe = currentUserId == targetId;

    if (_isMe && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/profile');
      });
      return;
    }

    final results = await Future.wait([
      _profileService.isFollowing(targetId),
      _profileService.getFollowCounts(targetId),
      _profileService.getFollowRequestStatus(targetId),
    ]);

    if (mounted) {
      setState(() {
        _profile = profile;
        _isFollowing = results[0] as bool;
        final counts = results[1] as Map<String, int>;
        _followersCount = counts['followers'] ?? 0;
        _followingCount = counts['following'] ?? 0;
        _requestStatus = results[2] as String?;
      });
    }
  }

  void _navigateToUserList(String type) async {
    if (_profile == null) return;
    
    final isPrivate = _profile!['is_private'] ?? false;
    if (isPrivate && !_isFollowing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Esta cuenta es privada. Sigue a la cuenta para ver su lista."))
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListScreen(
          userId: _profile!['id'],
          title: type == 'followers' ? "Seguidores" : "Siguiendo",
          type: type,
        ),
      ),
    );
    _loadInitialData();
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    final String targetId = _profile!['id'];
    final bool isPrivate = _profile!['is_private'] ?? false;

    if (_isFollowing) {
      setState(() {
        _isFollowing = false;
        _followersCount--;
      });
      await _profileService.unfollowUser(targetId);
    } else if (_requestStatus == 'pending') {
      setState(() {
        _requestStatus = null;
      });
      await _profileService.cancelFollowRequest(targetId);
    } else {
      if (isPrivate) {
        setState(() {
          _requestStatus = 'pending';
        });
        await _profileService.followUser(targetId);
      } else {
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
        await _profileService.followUser(targetId);
      }
    }
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
        }

        if (_profile == null) {
          return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
        }

        final displayName = _profile!['display_name'] ?? _profile!['username'] ?? "Artista";
        final isVerified = _profile!['is_verified'] ?? false;
        final bannerUrl = _profile!['banner_url'];
        final isPrivate = _profile!['is_private'] ?? false;
        final userId = _profile!['id'];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() { _initFuture = _loadInitialData(); });
              await _initFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 180, 
                        width: double.infinity, 
                        color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[300],
                        child: bannerUrl != null 
                          ? CachedNetworkImage(
                              imageUrl: bannerUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.transparent),
                            )
                          : Container(color: const Color(0xFF6C63FF)),
                      ),
                      Positioned(
                        top: 40,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black38,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: CachedNetworkImageProvider(_profile!['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isVerified) const SizedBox(width: 26), 
                            Text(
                              displayName, 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Colors.blue, size: 20),
                            ],
                          ],
                        ),
                        Text("@${_profile!['username']}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Text(
                          _profile!['bio'] ?? "Artista en Artist's Cottage ✨", 
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<Map<String, int>>(
                    stream: _profileService.getFollowCountsStream(userId),
                    builder: (context, countSnapshot) {
                      final counts = countSnapshot.data ?? {
                        'followers': _followersCount, 
                        'following': _followingCount
                      };
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _postService.getUserPostsStream(userId),
                                  builder: (context, postSnapshot) => _StatItem(label: "Posts", value: "${postSnapshot.data?.length ?? 0}"),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _navigateToUserList('followers'),
                                  child: _StatItem(label: "Seguidores", value: "${counts['followers']}"),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _navigateToUserList('following'),
                                  child: _StatItem(label: "Siguiendo", value: "${counts['following']}"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
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
                              backgroundColor: (_isFollowing || _requestStatus == 'pending')
                                ? (theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200]) 
                                : const Color(0xFF6C63FF),
                              foregroundColor: (_isFollowing || _requestStatus == 'pending')
                                ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) 
                                : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isFollowing 
                                ? "Siguiendo" 
                                : (_requestStatus == 'pending' ? "Solicitado" : "Seguir"), 
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, thickness: 1, color: theme.dividerColor),
                  
                  if (isPrivate && !_isFollowing)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text("Esta cuenta es privada", style: theme.textTheme.titleMedium),
                          const Text("Sigue a este artista para ver sus obras.", textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _postService.getUserPostsStream(userId),
                      builder: (context, postSnapshot) {
                        final posts = postSnapshot.data ?? [];
                        if (posts.isEmpty && postSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1, 
                            mainAxisSpacing: 1,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return GestureDetector(
                              onTap: () {
                                final int? idNum = int.tryParse(post['id'].toString());
                                final String code = idNum != null ? ShortcodeUtils.encode(idNum) : post['id'].toString();
                                Navigator.pushNamed(context, "/post/$code");
                              },
                              child: CachedNetworkImage(
                                imageUrl: post['image_url'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                              ),
                            );
                          },
                        );
                      }
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
