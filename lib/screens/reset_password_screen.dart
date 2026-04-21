import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _updatePassword() async {
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña debe tener al menos 6 caracteres")),
      );
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contraseña actualizada con éxito")),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Contraseña", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Color(0xFF6C63FF)),
            const SizedBox(height: 24),
            const Text(
              "Restablece tu acceso",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Escribe tu nueva contraseña segura y confírmala para entrar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Campo 1: Nueva Contraseña
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6C63FF)),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Campo 2: Confirmar Contraseña
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Confirma la contraseña',
                prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFF6C63FF)),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),

            // Botón de Acción
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("ACTUALIZAR Y ENTRAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
