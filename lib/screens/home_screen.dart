import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/post_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist's Cottage", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/explore'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postService.postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final rawPosts = snapshot.data ?? [];

          if (rawPosts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("¡Todavía no hay publicaciones!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Usamos un FutureBuilder dentro del StreamBuilder para traer los nombres de los perfiles
          // ya que los Streams de Supabase no traen datos de otras tablas automáticamente
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _postService.attachProfiles(rawPosts),
            builder: (context, profileSnapshot) {
              final posts = profileSnapshot.data ?? rawPosts;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final profile = post['profiles'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: PostCard(
                      username: profile != null ? profile['display_name'] ?? profile['username'] ?? "Artista" : "Artista",
                      handle: "@${profile != null ? profile['username'] ?? 'user' : 'user'}",
                      time: "Reciente",
                      content: post['content'] ?? "",
                      imageUrl: post['image_url'] ?? "",
                      profileImageUrl: profile != null ? profile['avatar_url'] : null,
                      likes: 0,
                      comments: 0,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
