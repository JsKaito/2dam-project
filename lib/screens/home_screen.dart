import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/post_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = PostService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist's Cottage", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: postService.postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("¡Todavía no hay publicaciones!", style: TextStyle(color: Colors.grey)),
                  Text("Sé el primero en subir tu arte.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: PostCard(
                  username: "Artista", // Para username en tiempo real necesitaríamos un JOIN más complejo en Stream
                  handle: "@user",
                  time: "Reciente",
                  content: post['content'] ?? "",
                  imageUrl: post['image_url'] ?? "",
                  likes: 0,
                  comments: 0,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
