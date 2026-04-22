import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart';

class NavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const NavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _selectedIndex;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _syncUrlWithIndex(_selectedIndex);
  }

  // Método para obtener la pantalla actual. 
  // Al no usar IndexedStack, la pantalla se crea de nuevo cada vez, 
  // provocando que se muestren los estados de carga.
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen(key: ValueKey('home'));
      case 1:
        return const ExploreScreen(key: ValueKey('explore'));
      case 3:
        return const NotificationsScreen(key: ValueKey('notifications'));
      case 4:
        return const ProfileScreen(key: ValueKey('profile'));
      default:
        return const HomeScreen();
    }
  }

  void _syncUrlWithIndex(int index) {
    final Map<int, String> routes = {
      0: '/home',
      1: '/explore',
      3: '/notifications',
      4: '/profile',
    };
    if (routes.containsKey(index)) {
      html.window.history.pushState(null, '', routes[index]!);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreatePost();
    } else {
      setState(() {
        _selectedIndex = index;
      });
      _syncUrlWithIndex(index);
    }
  }

  void _showCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un simple contenedor que cambia el hijo. 
      // Al cambiar el índice, el widget anterior muere y el nuevo carga sus datos.
      body: _getCurrentScreen(),
      bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.notificationsStream,
        builder: (context, snapshot) {
          final unreadCount = snapshot.hasData 
              ? snapshot.data!.where((n) => n['is_read'] == false).length 
              : 0;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF121212),
            selectedItemColor: const Color(0xFF6C63FF),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text(unreadCount.toString()),
                  isLabelVisible: unreadCount > 0,
                  child: Icon(_selectedIndex == 3 ? Icons.notifications : Icons.notifications_none),
                ),
                label: 'Notifications',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          );
        }
      ),
    );
  }
}
