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
import 'package:artists_alley/screens/user_list_screen.dart';
import 'package:artists_alley/navigation_wrapper.dart';
import 'package:artists_alley/services/shortcode_utils.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: 'https://yrbzkgfomjqilmyxzfqe.supabase.co',
    anonKey: 'sb_publishable_btZL2OIyfvGSBnbbegPR5g_VyUN1Hz8',
  );

  final prefs = await SharedPreferences.getInstance();
  final String? savedTheme = prefs.getString('theme_mode');
  themeNotifier.value = (savedTheme == 'light') ? ThemeMode.light : ThemeMode.dark;

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
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const AuthGuardian(),
          
          // SISTEMA DE RUTAS CON SHORTCODES
          onGenerateRoute: (settings) {
            final name = settings.name ?? '';
            
            if (name.startsWith('/user/')) {
              final username = name.replaceFirst('/user/', '');
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => NavigationWrapper(content: UserProfileScreen(username: username)),
              );
            }
            
            if (name.startsWith('/post/')) {
              final rawId = name.replaceFirst('/post/', '');
              // Intentamos decodificar el shortcode si no es un número puro
              final String finalPostId = ShortcodeUtils.parseId(rawId).toString();
              
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => NavigationWrapper(content: PostDetailsScreen(postId: finalPostId)),
              );
            }

            switch (name) {
              case '/home':
                return MaterialPageRoute(settings: settings, builder: (_) => const NavigationWrapper(initialIndex: 0));
              case '/explore':
                return MaterialPageRoute(settings: settings, builder: (_) => const NavigationWrapper(initialIndex: 1));
              case '/notifications':
                return MaterialPageRoute(settings: settings, builder: (_) => const NavigationWrapper(initialIndex: 3));
              case '/profile':
                return MaterialPageRoute(settings: settings, builder: (_) => const NavigationWrapper(initialIndex: 4));
              case '/login':
                return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
              case '/register':
                return MaterialPageRoute(settings: settings, builder: (_) => const RegisterScreen());
              default:
                return null;
            }
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFDFDFD),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
      ),
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
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) return const NavigationWrapper(initialIndex: 0);
        return const LoginScreen();
      },
    );
  }
}
