import 'package:flutter/material.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist's Cottage", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PostCard(
            username: "Elena Abstracta",
            handle: "@abstract_vibes",
            time: "Hace 1 día",
            content: "Paisaje de montañas al óleo. 3 semanas de trabajo 🏔️ #OilPainting #Landscape",
            imageUrl: "https://picsum.photos/id/1015/600/400",
            likes: 7,
            comments: 0,
          ),
          SizedBox(height: 16),
          PostCard(
            username: "Elena Abstracta",
            handle: "@abstract_vibes",
            time: "Hace 4 días",
            content: "Tutorial: Cómo dibujar ojos expresivos. Guardad este post! 👁️ #Tutorial",
            imageUrl: "https://picsum.photos/id/1012/600/400",
            likes: 12,
            comments: 2,
          ),
        ],
      ),
    );
  }
}
