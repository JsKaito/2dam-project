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
        title: const Text("Explorar", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar artistas o temas...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
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
