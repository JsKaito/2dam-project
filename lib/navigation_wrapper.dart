import 'package:flutter/material.dart';
import 'package:artists_cottage/screens/home_screen.dart';
import 'package:artists_cottage/screens/explore_screen.dart';
import 'package:artists_cottage/screens/create_post_screen.dart';
import 'package:artists_cottage/screens/notifications_screen.dart';
import 'package:artists_cottage/screens/profile_screen.dart';
import 'package:artists_cottage/services/notification_service.dart';

class NavigationWrapper extends StatefulWidget {
  final Widget? content;
  final int initialIndex;

  const NavigationWrapper({super.key, this.content, this.initialIndex = 0});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = NotificationService();

    if (widget.content != null) {
      return Scaffold(
        body: widget.content,
        bottomNavigationBar: _buildBottomBar(notificationService, theme, isSubPage: true),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const HomeScreen(),
          const ExploreScreen(),
          const CreatePostScreen(isIntegrated: true),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(notificationService, theme, isSubPage: false),
    );
  }

  Widget _buildBottomBar(NotificationService notificationService, ThemeData theme, {required bool isSubPage}) {
    final isDark = theme.brightness == Brightness.dark;
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: notificationService.notificationsStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData ? snapshot.data!.where((n) => n['is_read'] == false).length : 0;

        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => _handleNavigation(index, isSubPage),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor, // Usamos el color de fondo para que se integre mejor
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.home_filled : Icons.home_outlined, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Icons.explore : Icons.explore_outlined, size: 28),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? const Color(0xFF6C63FF) : const Color(0xFF6C63FF).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _currentIndex == 2 ? [
                    BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: const Icon(Icons.photo_camera, color: Colors.white, size: 24),
              ),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                child: Icon(_currentIndex == 3 ? Icons.notifications : Icons.notifications_none, size: 28),
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 4 ? Icons.person : Icons.person_outline, size: 28),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }

  void _handleNavigation(int index, bool isSubPage) {
    if (isSubPage) {
      final Map<int, String> routes = {0: '/home', 1: '/explore', 3: '/notifications', 4: '/profile'};
      if (index == 2) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (routes.containsKey(index)) {
        Navigator.pushNamedAndRemoveUntil(context, routes[index]!, (route) => false);
      }
      return;
    }

    if (index != _currentIndex) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentIndex = index;
      });
    }
  }
}
