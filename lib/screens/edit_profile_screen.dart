import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = true;
  String? _avatarUrl;
  String? _bannerUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getCurrentProfile();
    if (profile != null) {
      setState(() {
        _nameController.text = profile['display_name'] ?? '';
        _usernameController.text = profile['username'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _avatarUrl = profile['avatar_url'];
        _bannerUrl = profile['banner_url'];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isLoading = true);
      final bytes = await image.readAsBytes();
      
      String? newUrl;
      if (isAvatar) {
        newUrl = await _profileService.uploadAvatar(bytes);
        if (newUrl != null) setState(() => _avatarUrl = newUrl);
      } else {
        newUrl = await _profileService.uploadBanner(bytes);
        if (newUrl != null) setState(() => _bannerUrl = newUrl);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final ok = await _profileService.updateProfile(
      username: _usernameController.text,
      displayName: _nameController.text,
      bio: _bioController.text,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) Navigator.pop(context);
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        actions: [IconButton(icon: const Icon(Icons.check, color: Color(0xFF6C63FF)), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SECCIÓN BANNER
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: const Color(0xFF1E1E1E),
                    child: _bannerUrl != null 
                      ? Image.network(_bannerUrl!, fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.add_a_photo, color: Colors.grey)),
                  ),
                  Positioned(
                    right: 8, bottom: 8,
                    child: CircleAvatar(backgroundColor: Colors.black54, radius: 18, child: const Icon(Icons.camera_alt, size: 18, color: Colors.white)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // SECCIÓN AVATAR
            GestureDetector(
              onTap: () => _pickImage(true),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_avatarUrl ?? ProfileService.defaultAvatarUrl),
                  ),
                  const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Color(0xFF6C63FF), child: Icon(Icons.edit, size: 15, color: Colors.white))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildField("Nombre visible", _nameController),
                  const SizedBox(height: 16),
                  _buildField("Nombre de usuario", _usernameController),
                  const SizedBox(height: 16),
                  _buildField("Biografía", _bioController, maxLines: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
