import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildNotificationItem("Alex Sketch", "started following you", "24 days ago"),
          _buildNotificationItem("María Acuarela", "started following you", "28 days ago"),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String name, String action, String time) {
    return ListTile(
      leading: Stack(
        children: [
          const CircleAvatar(backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=user")),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
              child: const Icon(Icons.person_add, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white),
          children: [
            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: " $action"),
          ],
        ),
      ),
      subtitle: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}
