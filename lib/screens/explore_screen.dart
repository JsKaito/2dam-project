import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/post_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Buscar artistas o temas...",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        // Cada vez que cambie _searchQuery, el FutureBuilder se disparará de nuevo
        future: _postService.getGlobalPosts(query: _searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(child: Text("No se han encontrado resultados."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final profile = post['profiles'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(
                  username: profile != null ? profile['display_name'] ?? profile['username'] ?? "Artista" : "Artista",
                  handle: "@${profile != null ? profile['username'] ?? 'user' : 'user'}",
                  time: "Explorar",
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
      ),
    );
  }
}
