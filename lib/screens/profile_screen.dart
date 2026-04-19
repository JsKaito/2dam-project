import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

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
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _profileService.profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!profileSnapshot.hasData) {
            return const Center(child: Text("Error al cargar perfil"));
          }

          final profile = profileSnapshot.data!;
          final userId = profile['id'];
          final displayName = profile['display_name'] ?? profile['username'] ?? "Artista";
          final username = profile['username'] ?? "user";

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      color: const Color(0xFF6C63FF),
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
                        backgroundColor: const Color(0xFF121212),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: profile['avatar_url'] != null 
                              ? NetworkImage(profile['avatar_url']) 
                              : const NetworkImage("https://i.pravatar.cc/150?u=user"),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text("@$username", style: const TextStyle(color: Colors.grey)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    profile['bio'] ?? "Sin biografía todavía. ✨",
                    textAlign: TextAlign.center,
                  ),
                ),
                
                if (userId != null)
                  FutureBuilder<List<dynamic>>(
                    future: _postService.getUserPosts(userId),
                    builder: (context, postsSnapshot) {
                      final posts = postsSnapshot.data ?? [];
                      
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatItem(label: "Posts", value: "${posts.length}"),
                                const SizedBox(width: 40),
                                const _StatItem(label: "Seguidores", value: "0"),
                                const SizedBox(width: 40),
                                const _StatItem(label: "Siguiendo", value: "0"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Editar Perfil"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          const Divider(height: 40, color: Color(0xFF1E1E1E)),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: PostCard(
                                  username: displayName,
                                  handle: "@$username",
                                  time: "Post propio",
                                  content: post['content'] ?? "",
                                  imageUrl: post['image_url'] ?? "",
                                  likes: 0,
                                  comments: 0,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
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
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
