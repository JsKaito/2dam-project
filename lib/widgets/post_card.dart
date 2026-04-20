import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String handle; // El @usuario
  final String time;
  final String content;
  final String imageUrl;
  final String? profileImageUrl;
  final int likes;
  final int comments;
  final String userId;

  const PostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.time,
    required this.content,
    required this.imageUrl,
    this.profileImageUrl,
    required this.likes,
    required this.comments,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enlace Real: Navegación por ruta nombrada
          InkWell(
            onTap: () {
              // Extraemos el username sin el @ para la URL
              final cleanHandle = handle.startsWith('@') ? handle.substring(1) : handle;
              Navigator.pushNamed(context, '/user/$cleanHandle');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                        ? NetworkImage(profileImageUrl!) 
                        : const NetworkImage(ProfileService.defaultAvatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        Text("$handle · $time", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(content),
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
              const SizedBox(width: 4),
              Text("$likes", style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
              const SizedBox(width: 4),
              Text("$comments", style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
