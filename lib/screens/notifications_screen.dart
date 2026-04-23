import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import 'post_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Al entrar en la pantalla, marcamos todo como leído automáticamente
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    // Damos un pequeño respiro para que la UI se asiente antes de limpiar
    await Future.delayed(const Duration(milliseconds: 500));
    await _notificationService.markAllAsRead();
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "Reciente";
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return "Hace unos segundos";
    if (difference.inMinutes < 60) return "Hace ${difference.inMinutes} min";
    if (difference.inHours < 24) return "Hace ${difference.inHours} h";
    if (difference.inDays < 7) return "Hace ${difference.inDays} d";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.notificationsStream,
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
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No tienes notificaciones todavía.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final sender = notif['sender_profile'];
              final bool isRead = notif['is_read'] ?? false;

              String message = "";
              switch (notif['type']) {
                case 'like':
                  message = " le dio a me gusta a tu publicación.";
                  break;
                case 'comment':
                  message = " comentó tu publicación.";
                  break;
                case 'follow':
                  message = " ha empezado a seguirte.";
                  break;
                case 'reply':
                  message = " respondió a tu comentario.";
                  break;
                default:
                  message = " interactuó contigo.";
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(sender?['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                ),
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black), 
                      fontSize: 14
                    ),
                    children: [
                      TextSpan(
                        text: "${sender?['username'] ?? 'Alguien'}", 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      TextSpan(text: message),
                    ],
                  ),
                ),
                subtitle: Text(_formatTimestamp(notif['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                // El punto azul solo sale si no ha sido leído (se quitará solo al entrar)
                trailing: isRead ? null : const CircleAvatar(radius: 4, backgroundColor: Color(0xFF6C63FF)),
                onTap: () {
                  _notificationService.markAsRead(notif['id']);
                  if (notif['post_id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(postId: notif['post_id'].toString()),
                      ),
                    );
                  } else if (notif['type'] == 'follow') {
                    Navigator.pushNamed(context, '/user/${sender?['username']}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
