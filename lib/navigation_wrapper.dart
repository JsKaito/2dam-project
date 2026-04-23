import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:artists_alley/screens/home_screen.dart';
import 'package:artists_alley/screens/explore_screen.dart';
import 'package:artists_alley/screens/create_post_screen.dart';
import 'package:artists_alley/screens/notifications_screen.dart';
import 'package:artists_alley/screens/profile_screen.dart';
import 'package:artists_alley/screens/post_details_screen.dart';
import 'package:artists_alley/services/notification_service.dart';

class NavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const NavigationWrapper({super.key, this.initialIndex = 0});

  static final GlobalKey<NavigationWrapperState> navigationKey = GlobalKey<NavigationWrapperState>();

  @override
  State<NavigationWrapper> createState() => NavigationWrapperState();
}

class NavigationWrapperState extends State<NavigationWrapper> {
  late int _selectedIndex;
  String? _currentPostId;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _syncUrlWithIndex(_selectedIndex);
  }

  void setIndex(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _currentPostId = null; // Al cambiar de pestaña principal, cerramos el post
    });
    _syncUrlWithIndex(index);
  }

  void showPost(String postId) {
    setState(() {
      _currentPostId = postId;
    });
  }

  void hidePost() {
    setState(() {
      _currentPostId = null;
    });
  }

  Widget _getCurrentScreen() {
    if (_currentPostId != null) {
      return PostDetailsScreen(postId: _currentPostId!);
    }

    switch (_selectedIndex) {
      case 0: return const HomeScreen(key: ValueKey('home'));
      case 1: return const ExploreScreen(key: ValueKey('explore'));
      case 3: return const NotificationsScreen(key: ValueKey('notifications'));
      case 4: return const ProfileScreen(key: ValueKey('profile'));
      default: return const HomeScreen();
    }
  }

  void _syncUrlWithIndex(int index) {
    final Map<int, String> routes = {0: '/home', 1: '/explore', 3: '/notifications', 4: '/profile'};
    if (routes.containsKey(index)) html.window.history.pushState(null, '', routes[index]!);
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreatePost();
    } else {
      setIndex(index);
    }
  }

  void _showCreatePost() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.notificationsStream,
        builder: (context, snapshot) {
          final unreadCount = snapshot.hasData ? snapshot.data!.where((n) => n['is_read'] == false).length : 0;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
            selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
            unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: theme.bottomNavigationBarTheme.elevation,
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
                  child: const Icon(Icons.photo_camera, color: Colors.white),
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
