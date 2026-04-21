import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/post_details_screen.dart';
import 'screens/reset_password_screen.dart';
import 'navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: 'https://yrbzkgfomjqilmyxzfqe.supabase.co',
    anonKey: 'sb_publishable_btZL2OIyfvGSBnbbegPR5g_VyUN1Hz8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Artist's Cottage",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGuardian(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const NavigationWrapper(initialIndex: 0),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == null) return null;
        
        final uri = Uri.parse(settings.name!);

        // Ruta: /user/username
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'user') {
          return MaterialPageRoute(
            builder: (context) => UserProfileScreen(username: uri.pathSegments[1]),
            settings: settings,
          );
        }

        // Ruta: /post/id
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'post') {
          return MaterialPageRoute(
            builder: (context) => PostDetailsScreen(postId: uri.pathSegments[1]),
            settings: settings,
          );
        }
        
        return null;
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
    // Escuchamos eventos especiales como la recuperación de contraseña
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Supabase.instance.client.auth.signOut();
          });
          return const LoginScreen();
        }

        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        
        if (session != null) {
          return const NavigationWrapper(initialIndex: 0);
        }

        if (snapshot.connectionState == ConnectionState.active || snapshot.hasData) {
          return const LoginScreen();
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        );
      },
    );
  }
}
