import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final email = _emailController.text;
    final password = _passwordController.text;

    final success = await AuthService().login(email, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email o contraseña incorrectos")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.palette, size: 80, color: Color(0xFF6C63FF)),
            const SizedBox(height: 24),
            const Text(
              "Artist's Cottage",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text("¡Bienvenido!", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: const Icon(Icons.visibility_outlined),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Iniciar sesión", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("¿No tienes una cuenta? "),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("Regístrate", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
