import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'post_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      userData['bio'] ?? "Sin biografía todavía. ✨", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  ),
                  
                  StreamBuilder<Map<String, int>>(
                    stream: _profileService.getFollowCountsStream(userId),
                    builder: (context, countSnapshot) {
                      final counts = countSnapshot.data ?? {'followers': 0, 'following': 0};
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _postService.getUserPostsStream(userId),
                            builder: (context, postSnapshot) => _StatItem(label: "Posts", value: "${postSnapshot.data?.length ?? 0}"),
                          ),
                          const SizedBox(width: 40),
                          _StatItem(label: "Seguidores", value: "${counts['followers']}"),
                          const SizedBox(width: 40),
                          _StatItem(label: "Siguiendo", value: "${counts['following']}"),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Editar Perfil"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.brightness == Brightness.dark ? Colors.white : theme.primaryColor,
                      side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey : theme.primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  
                  // DIVIDER PEGADO AL GRID
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
                          padding: EdgeInsets.zero, // Padding cero para que pegue al divider
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1, 
                            mainAxisSpacing: 1,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => PostDetailsScreen(postId: post['id'].toString()))
                              ),
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
