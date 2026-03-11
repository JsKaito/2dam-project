import 'package:flutter/material.dart';
import '../widgets/post_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text("Trending Today", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          PostCard(
            username: "Art Master",
            handle: "@art_master",
            time: "2 hours ago",
            content: "Check out this new landscape! 🎨",
            imageUrl: "https://picsum.photos/id/1016/600/400",
            likes: 45,
            comments: 5,
          ),
        ],
      ),
    );
  }
}
