import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No tienes notificaciones todavía", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final String? fromUsername = notif['from_username'];
              
              return ListTile(
                onTap: fromUsername != null ? () {
                  // Enlace Real: Navegación por ruta nombrada
                  Navigator.pushNamed(context, '/user/$fromUsername');
                } : null,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  backgroundImage: notif['from_avatar_url'] != null 
                    ? NetworkImage(notif['from_avatar_url']) 
                    : const NetworkImage(ProfileService.defaultAvatarUrl),
                ),
                title: Text(
                  notif['title'] ?? "Notificación",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  notif['content'] ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}
