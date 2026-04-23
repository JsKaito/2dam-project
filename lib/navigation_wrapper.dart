import 'package:flutter/material.dart';
import 'package:artists_alley/screens/home_screen.dart';
import 'package:artists_alley/screens/explore_screen.dart';
import 'package:artists_alley/screens/create_post_screen.dart';
import 'package:artists_alley/screens/notifications_screen.dart';
import 'package:artists_alley/screens/profile_screen.dart';
import 'package:artists_alley/services/notification_service.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget? content;
  final int initialIndex;

  const NavigationWrapper({super.key, this.content, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = NotificationService();

    // Determinamos qué pantalla mostrar
    final Widget currentScreen = content ?? _getScreenFromIndex(initialIndex);

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.notificationsStream,
        builder: (context, snapshot) {
          final unreadCount = snapshot.hasData ? snapshot.data!.where((n) => n['is_read'] == false).length : 0;

          return BottomNavigationBar(
            currentIndex: initialIndex,
            onTap: (index) => _handleNavigation(context, index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
            selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
            unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_camera, color: Colors.white),
                ),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text(unreadCount.toString()),
                  isLabelVisible: unreadCount > 0,
                  child: Icon(initialIndex == 3 ? Icons.notifications : Icons.notifications_none),
                ),
                label: 'Notifications',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          );
        },
      ),
    );
  }

  Widget _getScreenFromIndex(int index) {
    switch (index) {
      case 0: return const HomeScreen();
      case 1: return const ExploreScreen();
      case 3: return const NotificationsScreen();
      case 4: return const ProfileScreen();
      default: return const HomeScreen();
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
      return;
    }
    
    final routes = {0: '/home', 1: '/explore', 3: '/notifications', 4: '/profile'};
    if (routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }
}
