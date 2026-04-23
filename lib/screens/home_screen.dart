import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/post_card.dart';
import '../services/post_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "Reciente";
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inSeconds < 60) return "Hace unos segundos";
      if (difference.inMinutes < 60) return "Hace ${difference.inMinutes} min";
      if (difference.inHours < 24) return "Hace ${difference.inHours} h";
      if (difference.inDays < 7) return "Hace ${difference.inDays} d";
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "Reciente";
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return const Center(child: Text("Inicia sesión para ver tu feed"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist's Cottage", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postService.getHomeFeedStream(userId),
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
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Sigue a otros artistas para ver sus obras aquí.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final profile = post['profiles'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: PostCard(
                  postId: post['id'].toString(),
                  username: profile != null ? profile['display_name'] ?? profile['username'] ?? "Artista" : "Artista",
                  handle: "@${profile != null ? profile['username'] ?? 'user' : 'user'}",
                  time: _formatTimestamp(post['created_at']),
                  title: post['title'],
                  content: post['content'] ?? "",
                  imageUrl: post['image_url'] ?? "",
                  profileImageUrl: profile != null ? profile['avatar_url'] : null,
                  likes: post['likes_count'] ?? 0,
                  comments: post['comments_count'] ?? 0,
                  isLiked: post['is_liked'] ?? false,
                  userId: post['user_id'],
                  isVerified: profile != null ? (profile['is_verified'] ?? false) : false,
                  authorName: post['author_name'],
                  captureDate: post['capture_date'],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
