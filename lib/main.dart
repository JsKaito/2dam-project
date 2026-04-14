import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // URL limpia sin '#'
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
      // Punto de entrada único
      home: const AuthCheck(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login': return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register': return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home': return MaterialPageRoute(builder: (_) => const NavigationWrapper(initialIndex: 0));
          case '/explore': return MaterialPageRoute(builder: (_) => const NavigationWrapper(initialIndex: 1));
          case '/notifications': return MaterialPageRoute(builder: (_) => const NavigationWrapper(initialIndex: 3));
          case '/profile': return MaterialPageRoute(builder: (_) => const NavigationWrapper(initialIndex: 4));
          default: return null;
        }
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Miramos si ya hay una sesión cargada en este instante
    final initialSession = Supabase.instance.client.auth.currentSession;

    // 2. Usamos el Stream para cambios futuros, pero con la sesión inicial ya puesta
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Si el stream aún no ha emitido pero tenemos sesión inicial, la usamos
        final session = snapshot.hasData ? snapshot.data!.session : initialSession;

        if (session != null) {
          return const NavigationWrapper(initialIndex: 0);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
