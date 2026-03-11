import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFF6C63FF),
                  child: const Center(
                    child: Text("Luna García", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                  ),
                ),
                const Positioned(
                  bottom: -50,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xFF121212),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=luna"),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            const Text("@artista_luna", style: TextStyle(color: Colors.grey)),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "🎨 Ilustradora digital | Amante del arte fantástico y surrealista | Comisiones abiertas ✨",
                textAlign: TextAlign.center,
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: "Posts", value: "1"),
                _StatItem(label: "Followers", value: "6"),
                _StatItem(label: "Following", value: "4"),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text("Edit Profile"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const Divider(height: 40, color: Color(0xFF1E1E1E)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: PostCard(
                username: "Luna García",
                handle: "@artista_luna",
                time: "12 days ago",
                content: "Experimentando con texturas en mi última pieza abstracta. El arte es libertad 🌈",
                imageUrl: "https://picsum.photos/id/1018/600/400",
                likes: 15,
                comments: 3,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
