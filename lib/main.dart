import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artists_alley/screens/login_screen.dart';
import 'package:artists_alley/screens/register_screen.dart';
import 'package:artists_alley/screens/user_profile_screen.dart';
import 'package:artists_alley/screens/post_details_screen.dart';
import 'package:artists_alley/screens/reset_password_screen.dart';
import 'package:artists_alley/screens/mfa_login_screen.dart';
import 'package:artists_alley/navigation_wrapper.dart';

// Gestor global de tema
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: 'https://yrbzkgfomjqilmyxzfqe.supabase.co',
    anonKey: 'sb_publishable_btZL2OIyfvGSBnbbegPR5g_VyUN1Hz8',
  );

  // Cargar el tema guardado antes de arrancar la app
  final prefs = await SharedPreferences.getInstance();
  final String? savedTheme = prefs.getString('theme_mode');
  if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else {
    themeNotifier.value = ThemeMode.dark;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: "Artist's Cottage",
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFDFDFD),
            primaryColor: const Color(0xFF6C63FF),
            cardColor: Colors.white,
            dividerColor: Colors.black12,
            textTheme: const TextTheme(
              displaySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              bodyLarge: TextStyle(color: Colors.black, fontSize: 16, height: 1.5),
              bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
              titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              labelSmall: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFDFDFD),
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
              iconTheme: IconThemeData(color: Colors.black),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
              color: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF6C63FF),
              unselectedItemColor: Colors.black26,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.light,
              surface: Colors.white,
              outline: Colors.black12,
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            primaryColor: const Color(0xFF6C63FF),
            cardColor: const Color(0xFF141414),
            dividerColor: Colors.white10,
            textTheme: const TextTheme(
              displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              bodyLarge: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
              bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              labelSmall: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white10, width: 1),
              ),
              color: const Color(0xFF141414),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF0A0A0A),
              selectedItemColor: Color(0xFF6C63FF),
              unselectedItemColor: Colors.white24,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
              surface: const Color(0xFF0A0A0A),
              outline: Colors.white10,
            ),
            useMaterial3: true,
          ),

          home: const AuthGuardian(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => NavigationWrapper(key: NavigationWrapper.navigationKey, initialIndex: 0),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/mfa-login': (context) => const MFALoginScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == null) return null;
            final uri = Uri.parse(settings.name!);
            if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'user') {
              return MaterialPageRoute(builder: (context) => UserProfileScreen(username: uri.pathSegments[1]), settings: settings);
            }
            if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'post') {
              return MaterialPageRoute(builder: (context) => PostDetailsScreen(postId: uri.pathSegments[1]), settings: settings);
            }
            return null;
          },
        );
      },
    );
  }
}

class AuthGuardian extends StatefulWidget {
  const AuthGuardian({super.key});
  @override
  State<AuthGuardian> createState() => _AuthGuardianState();
}

class _AuthGuardianState extends State<AuthGuardian> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        Navigator.pushNamed(context, '/reset-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) => Supabase.instance.client.auth.signOut());
          return const LoginScreen();
        }
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) return NavigationWrapper(key: NavigationWrapper.navigationKey, initialIndex: 0);
        if (snapshot.connectionState == ConnectionState.active || snapshot.hasData) return const LoginScreen();
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
      },
    );
  }
}
