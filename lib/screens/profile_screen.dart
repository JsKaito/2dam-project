import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
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

  Future<Map<String, dynamic>> _fetchProfileData(String userId) async {
    final results = await Future.wait([
      _profileService.getFollowCounts(userId),
      _postService.getUserPosts(userId),
      _profileService.getCurrentProfile(),
    ]);

    return {
      'counts': results[0] as Map<String, int>,
      'posts': results[1] as List<dynamic>,
      'profile': results[2] as Map<String, dynamic>?,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _profileService.profileStream,
        builder: (context, streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final userData = streamSnapshot.data;
          if (userData == null || userData.isEmpty) {
            return const Center(child: Text("Inicia sesión para ver tu perfil"));
          }

          final String userId = userData['id'];

          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchProfileData(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text("Error al cargar los datos"));
              }

              final data = snapshot.data!;
              final profile = data['profile'];
              final counts = data['counts'] as Map<String, int>;
              final posts = data['posts'] as List<dynamic>;

              final displayName = profile?['display_name'] ?? profile?['username'] ?? "Artista";
              final username = profile?['username'] ?? "user";
              final isVerified = profile?['is_verified'] ?? false;

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
                          Container(height: 180, width: double.infinity, color: const Color(0xFF6C63FF)),
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
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(profile?['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blue, size: 20),
                          ],
                        ],
                      ),
                      Text("@$username", style: const TextStyle(color: Colors.grey)),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(profile?['bio'] ?? "Sin biografía todavía. ✨", textAlign: TextAlign.center),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatItem(label: "Posts", value: "${posts.length}"),
                          const SizedBox(width: 40),
                          _StatItem(label: "Seguidores", value: "${counts['followers']}"),
                          const SizedBox(width: 40),
                          _StatItem(label: "Siguiendo", value: "${counts['following']}"),
                        ],
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
                      // Grid de fotos corregido para abrir el detalle
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => PostDetailsScreen(postId: post['id']))
                            ),
                            child: Image.network(post['image_url'], fit: BoxFit.cover),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
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
