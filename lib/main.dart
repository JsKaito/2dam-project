import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
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
      // Siempre arrancamos en AuthCheck
      home: const AuthCheck(),
      onGenerateRoute: (settings) {
        // Obtenemos la sesión actual en el momento de navegar
        final session = Supabase.instance.client.auth.currentSession;

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          
          // RUTAS PROTEGIDAS: Si no hay sesión, forzamos AuthCheck
          case '/home':
          case '/explore':
          case '/notifications':
          case '/profile':
            if (session == null) {
              return MaterialPageRoute(builder: (_) => const AuthCheck());
            }
            int index = 0;
            if (settings.name == '/explore') index = 1;
            if (settings.name == '/notifications') index = 3;
            if (settings.name == '/profile') index = 4;
            return MaterialPageRoute(builder: (_) => NavigationWrapper(initialIndex: index));
            
          default:
            return MaterialPageRoute(builder: (_) => const AuthCheck());
        }
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Mientras el SDK recupera la sesión del navegador
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const NavigationWrapper(initialIndex: 0);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
