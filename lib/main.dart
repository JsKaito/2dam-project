import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // URL limpia sin '#' para web
  usePathUrlStrategy();

  // Inicialización estándar (la persistencia viene activada por defecto)
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
      },
    );
  }
}

class AuthGuardian extends StatelessWidget {
  const AuthGuardian({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Manejo de errores de token (Refresh Token Not Found)
        if (snapshot.hasError) {
          // Si hay error de sesión, limpiamos localmente para poder loguear de nuevo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Supabase.instance.client.auth.signOut();
          });
          return const LoginScreen();
        }

        // 2. Si hay una sesión activa, vamos a la Home
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const NavigationWrapper(initialIndex: 0);
        }

        // 3. Si el stream ya cargó y no hay sesión, al Login
        if (snapshot.connectionState == ConnectionState.active || snapshot.hasData) {
          return const LoginScreen();
        }

        // 4. Cargador inicial instantáneo
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        );
      },
    );
  }
}
