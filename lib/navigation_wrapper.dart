import 'package:flutter/material.dart';
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
  }

  // Las pantallas se mantienen en memoria para que no se pierdan al cambiar
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const SizedBox.shrink(), // Placeholder para el botón de '+'
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {    if (index == 2) {
    _showCreatePost();
  } else {
    // Definimos las rutas según el index
    final Map<int, String> routes = {
      0: '/home',
      1: '/explore',
      3: '/notifications',
      4: '/profile',
    };

    if (routes.containsKey(index)) {
      // Esto cambia la URL en el navegador
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }
  }

  void _showCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    ).then((_) {
      // Al volver de crear el post, refrescamos el estado si es necesario
      setState(() {});
    });
  }

  void _updateWebUrl(int index) {
    final Map<int, String> routes = {
      0: '/home',
      1: '/explore',
      3: '/notifications',
      4: '/profile',
    };
    if (routes.containsKey(index)) {
      // En una app real usaríamos GoRouter, aquí simulamos el cambio visual
    }
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
