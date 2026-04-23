import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_alley/services/profile_service.dart';
import 'package:artists_alley/services/post_service.dart';
import 'package:artists_alley/services/shortcode_utils.dart';
import 'package:artists_alley/screens/settings_screen.dart';
import 'package:artists_alley/screens/edit_profile_screen.dart';
import 'package:artists_alley/screens/user_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();

  void _navigateToUserList(String userId, String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListScreen(
          userId: userId,
          title: type == 'followers' ? "Seguidores" : "Siguiendo",
          type: type,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _profileService.profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final userData = profileSnapshot.data;
          if (userData == null || userData.isEmpty) return const Center(child: Text("Inicia sesión"));

          final String userId = userData['id'];
          final isVerified = userData['is_verified'] ?? false;
          final bannerUrl = userData['banner_url'];

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
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
                          ? Image.network(bannerUrl, key: ValueKey(bannerUrl), fit: BoxFit.cover)
                          : Container(color: const Color(0xFF6C63FF)),
                      ),
                      Positioned(
                        top: 40,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
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
                            backgroundImage: NetworkImage(userData['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                            key: ValueKey(userData['avatar_url']),
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
                              userData['display_name'] ?? userData['username'] ?? "Artista", 
                              style: TextStyle(
                                fontSize: 22, 
                                fontWeight: FontWeight.bold, 
                                color: theme.textTheme.titleLarge?.color
                              )
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Colors.blue, size: 20),
                            ],
                          ],
                        ),
                        Text("@${userData['username']}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Text(
                          userData['bio'] ?? "Sin biografía todavía. ✨", 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  StreamBuilder<Map<String, int>>(
                    stream: _profileService.getFollowCountsStream(userId),
                    builder: (context, countSnapshot) {
                      final counts = countSnapshot.data ?? {'followers': 0, 'following': 0};
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
                                  onTap: () => _navigateToUserList(userId, 'followers'),
                                  child: _StatItem(label: "Seguidores", value: "${counts['followers']}"),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _navigateToUserList(userId, 'following'),
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
                  
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Editar Perfil"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.brightness == Brightness.dark ? Colors.white : theme.primaryColor,
                      side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey : theme.primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Divider(height: 1, thickness: 1, color: theme.dividerColor),
                  
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _postService.getUserPostsStream(userId),
                    builder: (context, snapshot) {
                      final posts = snapshot.data ?? [];
                      return Container(
                        color: theme.scaffoldBackgroundColor,
                        child: GridView.builder(
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
                                Navigator.pushNamed(context, '/post/$code');
                              },
                              child: Image.network(post['image_url'], fit: BoxFit.cover),
                            );
                          },
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
