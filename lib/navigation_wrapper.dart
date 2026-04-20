import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';

class NavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const NavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _syncUrlWithIndex(_selectedIndex);
  }

  // Las pantallas se mantienen en memoria
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const SizedBox.shrink(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _syncUrlWithIndex(int index) {
    final Map<int, String> routes = {
      0: '/home',
      1: '/explore',
      3: '/notifications',
      4: '/profile',
    };
    if (routes.containsKey(index)) {
      // Usamos pushState de HTML para que la URL cambie físicamente arriba
      // pero sin usar Navigator de Flutter para no reiniciar la app
      html.window.history.pushState(null, '', routes[index]!);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreatePost();
    } else {
      // IMPORTANTE: Aquí solo cambiamos el estado INTERNO del Wrapper
      // NO llamamos a Navigator.pushReplacementNamed porque eso reinicia todo
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
          const BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifications'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
