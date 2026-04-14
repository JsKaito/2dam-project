import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  XFile? _newAvatarFile;
  String? _currentAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final profile = await _profileService.getCurrentProfile();
    if (profile != null) {
      _usernameController.text = profile['username'] ?? '';
      _displayNameController.text = profile['display_name'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _currentAvatarUrl = profile['avatar_url'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() {
        _newAvatarFile = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    String? finalAvatarUrl = _currentAvatarUrl;

    if (_newAvatarFile != null) {
      dynamic fileToUpload;
      if (kIsWeb) {
        fileToUpload = await _newAvatarFile!.readAsBytes();
      } else {
        fileToUpload = File(_newAvatarFile!.path);
      }
      finalAvatarUrl = await _profileService.uploadAvatar(fileToUpload);
    }

    final success = await _profileService.updateProfile(
      username: _usernameController.text,
      displayName: _displayNameController.text,
      bio: _bioController.text,
      avatarUrl: finalAvatarUrl,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado correctamente")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar el perfil")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(
                onPressed: _saveProfile,
                child: const Text("Guardar", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
        ],
      ),
      body: _isLoading && _usernameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF1E1E1E),
                          backgroundImage: _newAvatarFile != null
                              ? (kIsWeb ? NetworkImage(_newAvatarFile!.path) : FileImage(File(_newAvatarFile!.path)) as ImageProvider)
                              : (_currentAvatarUrl != null ? NetworkImage(_currentAvatarUrl!) : null),
                          child: (_newAvatarFile == null && _currentAvatarUrl == null) 
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF6C63FF),
                              radius: 18,
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildEditField("Nombre Público", _displayNameController, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildEditField("Nombre de Usuario (@)", _usernameController, Icons.alternate_email),
                  const SizedBox(height: 16),
                  _buildEditField(
                    "Biografía",
                    _bioController,
                    Icons.info_outline,
                    maxLines: null,
                    minLines: 1,
                    alignTop: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {int? maxLines = 1, int? minLines, bool alignTop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          minLines: minLines,
          controller: controller,
          textAlignVertical: alignTop ? TextAlignVertical.top : null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: alignTop ? const EdgeInsets.only(bottom: 0) : EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: alignTop ? MainAxisAlignment.start : MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: alignTop ? const EdgeInsets.only(top: 12) : EdgeInsets.zero,
                    child: Icon(icon, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
