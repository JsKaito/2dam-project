import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MFALoginScreen extends StatefulWidget {
  const MFALoginScreen({super.key});

  @override
  State<MFALoginScreen> createState() => _MFALoginScreenState();
}

class _MFALoginScreenState extends State<MFALoginScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _verify() async {
    if (_codeController.text.length != 6) return;

    setState(() => _isLoading = true);
    final success = await _authService.verifyOTP(_codeController.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Código incorrecto o expirado")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seguridad Adicional")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Color(0xFF6C63FF)),
            const SizedBox(height: 24),
            const Text(
              "Tu cuenta tiene 2FA activado",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Introduce el código de 6 dígitos de tu aplicación de autenticación para continuar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration(
                hintText: "000000",
                counterText: "",
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
                onPressed: _isLoading ? null : _verify,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("VERIFICAR"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text("Volver al login", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
