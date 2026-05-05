import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final requests = await _profileService.getFollowRequests();
    if (mounted) {
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _accept(String requestId, String senderId) async {
    final success = await _profileService.acceptFollowRequest(requestId, senderId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Solicitud aceptada")),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al aceptar la solicitud. Verifica los permisos.")),
        );
      }
    }
  }

  Future<void> _reject(String requestId) async {
    await _profileService.rejectFollowRequest(requestId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud eliminada")),
      );
      _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes de seguimiento"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _requests.isEmpty
              ? const Center(child: Text("No tienes solicitudes pendientes."))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final sender = req['profiles'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(sender['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                      ),
                      title: Text(sender['display_name'] ?? sender['username'] ?? "Usuario"),
                      subtitle: Text("@${sender['username']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _accept(req['id'], sender['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _reject(req['id']),
                            child: const Text("Eliminar", style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
