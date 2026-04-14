import 'package:flutter/material.dart';
import '../services/notification_service.dart';

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
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1E1E1E),
                  child: Icon(Icons.notifications, color: Color(0xFF6C63FF), size: 20),
                ),
                title: Text(
                  notif['title'] ?? "Notificación",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  notif['content'] ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: const Text(
                  "Ahora",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
