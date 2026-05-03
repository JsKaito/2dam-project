import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_cottage/widgets/post_card.dart';
import 'package:artists_cottage/services/post_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final PostService _postService = PostService();

  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return const Center(child: Text("Inicia sesión para ver tu feed"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tus artistas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postService.getHomeFeedStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final posts = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              // Al ser un StreamBuilder, simplemente forzamos un rebuild del widget
              // o esperamos un pequeño delay para simular la carga si el stream es instantáneo
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFF6C63FF),
            child: posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("Sigue a otros artistas para ver sus obras aquí.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                  ),
          );
        },
      ),
    );
  }
}
