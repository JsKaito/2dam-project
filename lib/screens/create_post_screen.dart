import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';
import '../services/profile_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  
  XFile? _selectedImage;
  bool _isUploading = false;
  DateTime? _captureDate;
  
  String _selectedQuality = '1080p';
  String _authorType = 'Yo';
  
  Map<String, dynamic>? _myProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.getCurrentProfile();
    if (mounted) setState(() => _myProfile = p);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _captureDate = picked);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    int? qualityValue;
    double? maxWidth;
    
    if (_selectedQuality == '720p') { qualityValue = 80; maxWidth = 1280; }
    else if (_selectedQuality == '1080p') { qualityValue = 90; maxWidth = 1920; }
    else { qualityValue = 100; maxWidth = 3840; }

    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: qualityValue, maxWidth: maxWidth);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, añade un título y una imagen"))
      );
      return;
    }

    setState(() => _isUploading = true);
    
    String finalAuthor = "Anónimo";
    if (_authorType == 'Yo') {
      finalAuthor = "@${_myProfile?['username'] ?? 'artista'}";
    } else if (_authorType == 'Otra persona') {
      finalAuthor = _authorNameController.text.trim().isEmpty ? "Autor Desconocido" : _authorNameController.text.trim();
    }

    try {
      dynamic fileToUpload = kIsWeb ? await _selectedImage!.readAsBytes() : File(_selectedImage!.path);
      
      final success = await _postService.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageFile: fileToUpload,
        author: finalAuthor,
        captureDate: _captureDate?.toIso8601String(),
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Obra publicada con éxito!")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al publicar")));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text("Nueva Publicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isUploading 
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _uploadPost, 
                  child: const Text("Publicar", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16))
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ÁREA DE IMAGEN Y TEXTOS (Estilo Instagram)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: _selectedImage != null 
                          ? DecorationImage(
                              image: kIsWeb 
                                ? NetworkImage(_selectedImage!.path) 
                                : FileImage(File(_selectedImage!.path)) as ImageProvider,
                              fit: BoxFit.cover
                            ) 
                          : null,
                      ),
                      child: _selectedImage == null 
                        ? const Icon(Icons.add_a_photo_outlined, size: 30, color: Colors.grey)
                        : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: "Título de la obra...",
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(height: 1),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Escribe un pie de foto...",
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // CONFIGURACIONES ADICIONALES
            _buildListTile(
              icon: Icons.calendar_today_outlined,
              title: "Fecha de captura",
              trailing: Text(
                _captureDate == null ? "Opcional" : "${_captureDate!.day}/${_captureDate!.month}/${_captureDate!.year}",
                style: TextStyle(color: _captureDate == null ? Colors.grey : const Color(0xFF6C63FF)),
              ),
              onTap: _selectDate,
            ),
            
            _buildListTile(
              icon: Icons.person_outline,
              title: "Autoría",
              trailing: DropdownButton<String>(
                value: _authorType,
                underline: const SizedBox(),
                items: ['Yo', 'Otra persona', 'Anónimo'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == 'Yo' ? "Yo (@${_myProfile?['username'] ?? '...' })" : value, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _authorType = val!),
              ),
            ),
            
            if (_authorType == 'Otra persona')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _authorNameController,
                  decoration: InputDecoration(
                    hintText: "Nombre del autor...",
                    prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),

            _buildListTile(
              icon: Icons.high_quality_outlined,
              title: "Calidad de resolución",
              trailing: DropdownButton<String>(
                value: _selectedQuality,
                underline: const SizedBox(),
                items: ['720p', '1080p', '4K'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedQuality = val!),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required Widget trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
