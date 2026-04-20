import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  
  bool _pushLikes = true;
  bool _pushComments = true;
  bool _pushFollowers = true;
  bool _pushMentions = true;
  bool _isPrivate = false;
  bool _mfaEnabled = false;
  bool _tagApprovalRequired = false;
  List<String> _hiddenWordsTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile != null && mounted) {
        setState(() {
          _pushLikes = profile['push_likes'] ?? true;
          _pushComments = profile['push_comments'] ?? true;
          _pushFollowers = profile['push_followers'] ?? true;
          _pushMentions = profile['push_mentions'] ?? true;
          _isPrivate = profile['is_private'] ?? false;
          _mfaEnabled = profile['mfa_enabled'] ?? false;
          _tagApprovalRequired = profile['tag_approval_required'] ?? false;
          
          final String hw = profile['hidden_words'] ?? '';
          _hiddenWordsTags = hw.isNotEmpty ? hw.split(',').where((s) => s.trim().isNotEmpty).toList() : [];
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    setState(() {
      if (key == 'push_likes') _pushLikes = value;
      if (key == 'push_comments') _pushComments = value;
      if (key == 'push_followers') _pushFollowers = value;
      if (key == 'push_mentions') _pushMentions = value;
      if (key == 'is_private') _isPrivate = value;
      if (key == 'mfa_enabled') _mfaEnabled = value;
      if (key == 'tag_approval_required') _tagApprovalRequired = value;
    });
    await _profileService.updateSetting(key, value);
  }

  // --- SUB-PANELES CON STATEFULBUILDER (REACTIVIDAD REAL) ---

  void _showNotificationPanel() {
    _showPanel(
      title: "Notificaciones",
      builder: (context, setPanelState) => Column(
        children: [
          _buildSwitch("Likes", _pushLikes, (v) { setPanelState(() => _pushLikes = v); _update('push_likes', v); }),
          _buildSwitch("Comentarios", _pushComments, (v) { setPanelState(() => _pushComments = v); _update('push_comments', v); }),
          _buildSwitch("Seguidores", _pushFollowers, (v) { setPanelState(() => _pushFollowers = v); _update('push_followers', v); }),
          _buildSwitch("Menciones", _pushMentions, (v) { setPanelState(() => _pushMentions = v); _update('push_mentions', v); }),
        ],
      ),
    );
  }

  void _showPrivacyPanel() {
    _showPanel(
      title: "Privacidad y Etiquetas",
      builder: (context, setPanelState) => Column(
        children: [
          _buildSwitch("Cuenta Privada", _isPrivate, (v) { setPanelState(() => _isPrivate = v); _update('is_private', v); }),
          _buildSwitch("Aprobación de etiquetas", _tagApprovalRequired, (v) { setPanelState(() => _tagApprovalRequired = v); _update('tag_approval_required', v); }),
        ],
      ),
    );
  }

  void _showCommentPanel() {
    final tagController = TextEditingController();
    _showPanel(
      title: "Palabras Ocultas",
      builder: (context, setPanelState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Escribe una palabra y pulsa espacio", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _hiddenWordsTags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 11)),
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
              onDeleted: () {
                setPanelState(() => _hiddenWordsTags.remove(tag));
                _update('hidden_words', _hiddenWordsTags.join(','));
              },
            )).toList(),
          ),
          TextField(
            controller: tagController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "ej: spam"),
            onChanged: (val) {
              if (val.endsWith(' ')) {
                final newTag = val.trim();
                if (newTag.isNotEmpty && !_hiddenWordsTags.contains(newTag)) {
                  setPanelState(() => _hiddenWordsTags.add(newTag));
                  _update('hidden_words', _hiddenWordsTags.join(','));
                  tagController.clear();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSecurityPanel() {
    _showPanel(
      title: "Seguridad",
      builder: (context, setPanelState) => Column(
        children: [
          _buildTile(Icons.lock_outline, "Cambiar contraseña", () => _showChangePasswordDialog()),
          _buildSwitch("Verificación 2 Pasos (2FA)", _mfaEnabled, (v) { setPanelState(() => _mfaEnabled = v); _update('mfa_enabled', v); }),
          _buildTile(Icons.devices, "Cerrar otras sesiones", () async {
            await _profileService.logoutOthers();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Otras sesiones cerradas")));
          }),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final c = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text("Nueva Contraseña"),
      content: TextField(controller: c, obscureText: true, decoration: const InputDecoration(hintText: "Mínimo 6 caracteres")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        TextButton(onPressed: () async {
          if (c.text.length >= 6) {
            await _profileService.updatePassword(c.text);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Éxito")));
          }
        }, child: const Text("GUARDAR")),
      ],
    ));
  }

  void _confirmDelete() {
    int sec = 10;
    Timer? t;
    showDialog(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setD) {
      t ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (sec > 0 && mounted) setD(() => sec--);
        else timer.cancel();
      });
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("⚠️ ELIMINACIÓN REAL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("Confirmar en $sec segundos. Esta acción borrará TODO de Supabase."),
        actions: [
          TextButton(onPressed: () { t?.cancel(); Navigator.pop(context); }, child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: sec > 0 ? null : () async {
              final ok = await _profileService.deleteAccount();
              if (ok) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(sec > 0 ? "ESPERA ($sec)" : "ELIMINAR AHORA"),
          ),
        ],
      );
    }));
  }

  // --- UI HELPERS ---

  void _showPanel({required String title, required Widget Function(BuildContext, StateSetter) builder}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPanelState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
              const SizedBox(height: 16),
              builder(context, setPanelState),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text("Ajustes"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildGroup("Cuenta y Seguridad", [
            _buildTile(Icons.person_outline, "Perfil", () => Navigator.pushReplacementNamed(context, '/profile')),
            _buildTile(Icons.security, "Seguridad", _showSecurityPanel),
            _buildTile(Icons.verified_outlined, "Solicitar Verificación", () async {
              await _profileService.requestVerification();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud enviada")));
            }),
          ]),
          _buildGroup("Preferencias", [
            _buildTile(Icons.notifications_none, "Notificaciones", _showNotificationPanel),
            _buildTile(Icons.lock_person_outlined, "Privacidad", _showPrivacyPanel),
            _buildTile(Icons.chat_bubble_outline, "Filtros", _showCommentPanel),
          ]),
          _buildGroup("Datos", [
            _buildTile(Icons.download, "Descargar mis datos", () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Iniciando descarga...")));
              await _profileService.downloadUserDataReal();
            }),
          ]),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { await AuthService().logout(); Navigator.pushReplacementNamed(context, '/login'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)))),
          TextButton(onPressed: _confirmDelete, child: const Text("Eliminar cuenta definitivamente", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline))),
        ],
      ),
    );
  }

  Widget _buildGroup(String t, List<Widget> i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), child: Text(t.toUpperCase(), style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 11))), Container(decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)), child: Column(children: i))]);
  Widget _buildTile(IconData i, String t, VoidCallback o) => ListTile(leading: Icon(i, color: Colors.white, size: 22), title: Text(t), trailing: const Icon(Icons.chevron_right, size: 18), onTap: o);
  Widget _buildSwitch(String t, bool v, Function(bool) c) => SwitchListTile(title: Text(t), value: v, activeColor: const Color(0xFF6C63FF), onChanged: c);
}
