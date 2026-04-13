import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService();
  XFile? _selectedImage;
  bool _isUploading = false;

  // Función para seleccionar imagen
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // Función para subir el post
  Future<void> _uploadPost() async {
    if (_contentController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, añade un texto y una imagen")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Preparar el archivo según la plataforma (Web o Móvil)
      dynamic fileToUpload;
      if (kIsWeb) {
        fileToUpload = await _selectedImage!.readAsBytes();
      } else {
        fileToUpload = File(_selectedImage!.path);
      }

      final success = await _postService.createPost(
        content: _contentController.text,
        imageFile: fileToUpload,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Post publicado con éxito!")),
          );
          _contentController.clear();
          setState(() => _selectedImage = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al publicar. Revisa las políticas de Supabase.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Post", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isUploading 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16), 
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                )
              )
            : TextButton(
                onPressed: _uploadPost,
                child: const Text("Post", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "¿Qué tienes en mente? Compártelo...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
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
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text("Añadir una imagen", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      ],
                    )
                  : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
