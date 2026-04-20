import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import 'user_profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorar", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Buscar por nombre, @usuario o pie de foto...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Cuentas"),
              Tab(text: "Publicaciones"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildPostsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _postService.getGlobalPosts(query: _searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text("Sin resultados en publicaciones.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final profile = post['profiles'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                username: profile?['display_name'] ?? profile?['username'] ?? "Artista",
                handle: "@${profile?['username'] ?? 'user'}",
                time: "Reciente",
                content: post['content'] ?? "",
                imageUrl: post['image_url'] ?? "",
                profileImageUrl: profile?['avatar_url'],
                userId: post['user_id'] ?? "",
                likes: 0,
                comments: 0,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return FutureBuilder<List<dynamic>>(
      future: _profileService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text("No se encontraron artistas.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final username = user['username'] ?? "";
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user['avatar_url'] ?? ProfileService.defaultAvatarUrl),
              ),
              title: Text(user['display_name'] ?? username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("@$username", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              onTap: () {
                // Navegación Directa para mayor fiabilidad
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(username: username),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
