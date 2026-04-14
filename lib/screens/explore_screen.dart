import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/post_service.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = PostService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorar", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: postService.getGlobalPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final profile = post['profiles'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(
                  username: profile?['display_name'] ?? profile?['username'] ?? "Artista",
                  handle: "@${profile?['username'] ?? 'user'}",
                  time: "Explorar",
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
