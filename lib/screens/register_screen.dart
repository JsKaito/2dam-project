import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final ProfileService _profileService = ProfileService();
  int _currentStep = 0;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  Timer? _debounce;

  // Criterios de contraseña
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
    _usernameController.addListener(_onUsernameChanged);
    // Añadimos listener al email para refrescar el estado del botón "Continuar" mientras se escribe
    _emailController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    // Si el campo está vacío, reseteamos estados
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final username = _usernameController.text.trim();
      if (username.length >= 3) {
        setState(() => _isCheckingUsername = true);
        final available = await _profileService.isUsernameAvailable(username);
        if (mounted) {
          setState(() {
            _isUsernameAvailable = available;
            _isCheckingUsername = false;
          });
        }
      }
    });
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _hasMinLength = pass.length >= 6;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _hasSymbol = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _passwordsMatch = pass.isNotEmpty && pass == confirm;
    });
  }

  bool get _isStep1Valid =>
      _usernameController.text.trim().length >= 3 &&
      _isUsernameAvailable &&
      !_isCheckingUsername &&
      _emailController.text.trim().contains('@');

  void _nextStep() {
    if (_currentStep == 0 && _isStep1Valid) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    final success = await AuthService().register(
      _emailController.text.trim(),
      _passwordController.text,
      _usernameController.text.trim().toLowerCase(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al registrar. Verifica los datos.")));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¡Casi listo!", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
        content: const Text("Hemos enviado un correo de confirmación. Por favor, verifica tu cuenta para poder entrar."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)) : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(children: [_buildProgress(0), const SizedBox(width: 8), _buildProgress(1)]),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [_buildStep1(), _buildStep2()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int step) => Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentStep >= step ? const Color(0xFF6C63FF) : Colors.grey[800], borderRadius: BorderRadius.circular(2))));

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Paso 1: Identidad", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildTextField("Nombre de usuario", Icons.alternate_email, _usernameController),
          const SizedBox(height: 8),
          if (_usernameController.text.isNotEmpty)
            Row(
              children: [
                _isCheckingUsername ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_isUsernameAvailable ? Icons.check_circle : Icons.error, size: 14, color: _isUsernameAvailable ? Colors.green : Colors.red),
                const SizedBox(width: 6),
                Text(_isCheckingUsername ? "Comprobando..." : (_isUsernameAvailable ? "Nombre disponible" : "Este nombre ya está en uso"), style: TextStyle(fontSize: 12, color: _isUsernameAvailable ? Colors.green : Colors.red)),
              ],
            ),
          const SizedBox(height: 16),
          _buildTextField("Correo electrónico", Icons.mail_outline, _emailController),
          const SizedBox(height: 48),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isStep1Valid ? _nextStep : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), disabledBackgroundColor: Colors.grey[900]), child: const Text("Continuar"))),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Paso 2: Seguridad", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildTextField(
            "Contraseña", 
            Icons.lock_outline, 
            _passwordController, 
            isPassword: true,
            isVisible: _isPasswordVisible,
            onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            "Repite contraseña", 
            Icons.lock_clock_outlined, 
            _confirmPasswordController, 
            isPassword: true,
            isVisible: _isConfirmPasswordVisible,
            onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          const SizedBox(height: 24),
          _buildRequirement("Mínimo 6 caracteres", _hasMinLength),
          _buildRequirement("Al menos una mayúscula", _hasUppercase),
          _buildRequirement("Al menos un número", _hasNumber),
          _buildRequirement("Al menos un símbolo", _hasSymbol),
          _buildRequirement("Las contraseñas coinciden", _passwordsMatch),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: (_isLoading || !_passwordsMatch || !_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSymbol) ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)), child: _isLoading ? const CircularProgressIndicator() : const Text("Finalizar Registro"))),
        ],
      ),
    );
  }

  Widget _buildRequirement(String t, bool met) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(met ? Icons.check_circle : Icons.circle_outlined, size: 16, color: met ? Colors.green : Colors.grey), const SizedBox(width: 8), Text(t, style: TextStyle(color: met ? Colors.white : Colors.grey, fontSize: 13))]));

  Widget _buildTextField(String h, IconData i, TextEditingController c, {bool isPassword = false, bool isVisible = false, VoidCallback? onToggleVisibility}) {
    return TextField(
      controller: c, 
      obscureText: isPassword && !isVisible, 
      style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        hintText: h, 
        prefixIcon: Icon(i, color: const Color(0xFF6C63FF)), 
        suffixIcon: isPassword ? IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
          onPressed: onToggleVisibility,
        ) : null,
        filled: true, 
        fillColor: const Color(0xFF1E1E1E), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      )
    );
  }
}
