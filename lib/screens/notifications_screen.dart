import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import 'follow_requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    await _notificationService.markAllAsRead();
  }

  String _getTimeLabel(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) return "Hoy";
    if (aDate == yesterday) return "Ayer";
    if (now.difference(date).inDays < 7) return "Esta semana";
    return "Anteriormente";
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'like':
        return const Icon(Icons.favorite, color: Colors.redAccent, size: 12);
      case 'comment':
      case 'reply':
      case 'mention':
        return const Icon(Icons.chat_bubble_rounded, color: Color(0xFF6C63FF), size: 12);
      case 'follow':
        return const Icon(Icons.person_add_rounded, color: Colors.blueAccent, size: 12);
      case 'verification':
        return const Icon(Icons.verified, color: Colors.green, size: 12);
      default:
        return const Icon(Icons.notifications, color: Colors.amber, size: 12);
    }
  }

  void _openUserProfile(String? username) {
    if (username == null || username.isEmpty) return;
    Navigator.pushNamed(context, "/user/$username");
  }

  void _openPost(String? postId, {bool focusComments = false, String? commentId}) {
    if (postId == null || postId.toString().isEmpty) return;
    Navigator.pushNamed(
      context,
      "/post/$postId",
      arguments: {
        'focusComments': focusComments,
        'commentId': commentId,
      },
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final type = notif['type'] ?? '';
    final sender = notif['sender_profile'];
    _notificationService.markAsRead(notif['id']);

    if (type == 'follow') {
      _openUserProfile(sender?['username']);
      return;
    }

    if (type == 'comment' || type == 'reply' || type == 'mention') {
      _openPost(
        notif['post_id']?.toString(),
        focusComments: true,
        commentId: notif['comment_id']?.toString(),
      );
      return;
    }

    if (type == 'like') {
      _openPost(notif['post_id']?.toString());
      return;
    }

    if (type == 'verification') {
      Navigator.pushNamed(context, '/profile');
      return;
    }

    if (notif['post_id'] != null) {
      _openPost(notif['post_id']?.toString());
      return;
    }

    _openUserProfile(sender?['username']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: theme.primaryColor, size: 24),
            tooltip: "Marcar todas como leídas",
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todo al dia")));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final notifications = snapshot.data ?? [];
          
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var n in notifications) {
            final label = _getTimeLabel(n['created_at']);
            grouped.putIfAbsent(label, () => []).add(n);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _profileService.profileStream,
                  builder: (context, profileSnapshot) {
                    final isPrivate = profileSnapshot.data?['is_private'] ?? false;
                    if (!isPrivate) return const SizedBox.shrink();

                    return StreamBuilder<int>(
                      stream: _profileService.getFollowRequestsCountStream(),
                      builder: (context, countSnapshot) {
                        final count = countSnapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FollowRequestsScreen())),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                    ? [const Color(0xFF6C63FF).withOpacity(0.2), const Color(0xFF6C63FF).withOpacity(0.05)]
                                    : [const Color(0xFF6C63FF).withOpacity(0.1), Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.05), blurRadius: 10, spreadRadius: 1)
                                ]
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 48, width: 48,
                                        decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(14)),
                                        child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
                                      ),
                                      Positioned(
                                        right: -2, top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                          child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Solicitudes de seguimiento", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                        Text("Revisa quién quiere seguirte", style: TextStyle(color: theme.hintColor, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              if (notifications.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 80, color: theme.disabledColor.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text("No hay nada nuevo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.hintColor)),
                        const Text("Te avisaremos cuando alguien interactúe contigo.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else
                ...grouped.entries.map((group) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 15, 16, 10),
                          child: Text(group.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6C63FF), fontSize: 12, letterSpacing: 1.2)),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final notif = group.value[index];
                            final sender = notif['sender_profile'];
                            final bool isRead = notif['is_read'] ?? false;
                            final type = notif['type'] ?? '';
                            final bool isVerification = type == 'verification';

                            String message = "";
                            switch (type) {
                              case 'like': message = "le dio a me gusta a tu post."; break;
                              case 'comment': message = "comentó tu publicación."; break;
                              case 'follow': message = "ha empezado a seguirte."; break;
                              case 'reply': message = "respondió a tu comentario."; break;
                              case 'mention': message = "te mencionó en un comentario."; break;
                              case 'verification': message = "tu cuenta ha sido verificada."; break;
                              default: message = "interactuó contigo.";
                            }

                            final String displayName = isVerification
                              ? "Artist's Cottage"
                              : (sender?['username'] ?? 'Alguien');

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.transparent : const Color(0xFF6C63FF).withOpacity(isDark ? 0.05 : 0.03),
                                border: Border(left: BorderSide(color: isRead ? Colors.transparent : const Color(0xFF6C63FF), width: 3))
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: isVerification
                                        ? null
                                        : () {
                                            _notificationService.markAsRead(notif['id']);
                                            _openUserProfile(sender?['username']);
                                          },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2), width: 2),
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: isVerification ? const Color(0xFF6C63FF) : null,
                                          backgroundImage: isVerification
                                            ? null
                                            : NetworkImage(sender?['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                                          child: isVerification ? const Icon(Icons.verified, color: Colors.white, size: 24) : null,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF121212) : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                        ),
                                        child: _getIconForType(type),
                                      ),
                                    ),
                                  ],
                                ),
                                title: RichText(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14.5, height: 1.3),
                                    children: [
                                      TextSpan(
                                        text: "$displayName ",
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                        recognizer: isVerification
                                          ? null
                                          : (TapGestureRecognizer()..onTap = () {
                                              _notificationService.markAsRead(notif['id']);
                                              _openUserProfile(sender?['username']);
                                            }),
                                      ),
                                      TextSpan(text: message, style: const TextStyle(fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat.jm().format(DateTime.parse(notif['created_at'])),
                                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                                  ),
                                ),
                                onTap: () => _handleNotificationTap(notif),
                              ),
                            );
                          },
                          childCount: group.value.length,
                        ),
                      ),
                    ],
                  );
                }),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
