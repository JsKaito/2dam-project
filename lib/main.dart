import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Importación condicional
import 'package:flutter_web_plugins/url_strategy.dart' if (dart.library.io) 'package:artists_cottage/services/web_stub.dart';

import 'package:artists_cottage/screens/login_screen.dart';
import 'package:artists_cottage/screens/register_screen.dart';
import 'package:artists_cottage/screens/user_profile_screen.dart';
import 'package:artists_cottage/screens/post_details_screen.dart';
import 'package:artists_cottage/screens/reset_password_screen.dart';
import 'package:artists_cottage/screens/mfa_login_screen.dart';
import 'package:artists_cottage/navigation_wrapper.dart';
import 'package:artists_cottage/services/shortcode_utils.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await Supabase.initialize(
    url: 'https://yrbzkgfomjqilmyxzfqe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyYnprZ2ZvbWpxaWxteXh6ZnFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMDc4NjAsImV4cCI6MjA5MTY4Mzg2MH0.TAQZz_6shAIiY9FIVYCVk4-2hGtR4pehgIGAA_igxcg',
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.pkce : AuthFlowType.implicit,
    ),
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
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const AuthGuardian(),
          
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
              case '/mfa-login':
                return MaterialPageRoute(settings: settings, builder: (_) => const MFALoginScreen());
              case '/reset-password':
                return MaterialPageRoute(settings: settings, builder: (_) => const ResetPasswordScreen());
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
  StreamSubscription? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  late final AppLinks _appLinks;
  bool _isRecovering = false;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isRecovering = true);
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleIncomingLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    }, onError: (error) {
      debugPrint('Deep link stream error: $error');
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (uri.scheme != 'io.supabase.artistscottage') return;

    final params = _extractAuthParams(uri);
    final isRecovery = params['type'] == 'recovery';

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (e) {
      final refreshToken = params['refresh_token'];
      final accessToken = params['access_token'];
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );
        } catch (inner) {
          debugPrint('Manual session restore failed: $inner');
        }
      } else {
        debugPrint('Deep link handling failed: $e');
      }
    }

    if (!mounted) return;
    if (isRecovery) {
      setState(() => _isRecovering = true);
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/reset-password', (route) => false);
    }
  }

  Map<String, String> _extractAuthParams(Uri uri) {
    final params = <String, String>{}..addAll(uri.queryParameters);
    if (uri.fragment.isNotEmpty) {
      try {
        var fragment = uri.fragment;
        if (fragment.startsWith('?') || fragment.startsWith('#')) {
          fragment = fragment.substring(1);
        }
        if (fragment.startsWith('/')) {
          fragment = fragment.substring(1);
        }
        if (fragment.isNotEmpty) {
          params.addAll(Uri.splitQueryString(fragment));
        }
      } catch (_) {}
    }
    return params;
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecovering) return const ResetPasswordScreen();

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Si hay sesión pero falta el segundo factor (MFA), lo mandamos a la pantalla de código
      final needsMfa = session.user.appMetadata['aal'] == 'aal1' && 
                       session.user.appMetadata['mfa_enabled'] == true;
      
      if (needsMfa) return const MFALoginScreen();

      return const NavigationWrapper(initialIndex: 0);
    }
    return const LoginScreen();
  }
}
