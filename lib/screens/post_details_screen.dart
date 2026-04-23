import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_alley/services/post_service.dart';
import 'package:artists_alley/services/profile_service.dart';
import 'package:artists_alley/navigation_wrapper.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  final VoidCallback? onBack;

  const PostDetailsScreen({super.key, required this.postId, this.onBack});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _commentController = TextEditingController();
  
  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _replyingToId;
  String? _replyingToName;
  String? _rootParentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final postData = await _postService.getPostDetails(widget.postId);
    final commentsData = await _postService.getComments(widget.postId);
    
    if (mounted && postData != null) {
      final following = await _profileService.isFollowing(postData['user_id']);
      
      // ORDENACIÓN INICIAL: Los ordenamos por likes una sola vez al cargar
      commentsData.sort((a, b) => (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0));

      setState(() {
        _post = postData;
        _comments = commentsData;
        _isFollowing = following;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_post == null) return;
    setState(() => _isFollowing = !_isFollowing);
    try {
      if (!_isFollowing) await _profileService.unfollowUser(_post!['user_id']);
      else await _profileService.followUser(_post!['user_id']);
    } catch (e) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    }
  }

  Future<void> _handleLike() async {
    if (_post == null) return;
    final success = await _postService.toggleLike(widget.postId, _post!['is_liked']);
    if (success) {
      setState(() {
        _post!['is_liked'] = !_post!['is_liked'];
        _post!['likes_count'] += _post!['is_liked'] ? 1 : -1;
      });
    }
  }

  Future<void> _handleCommentLike(Map<String, dynamic> comment) async {
    final String commentId = comment['id'].toString();
    final success = await _postService.toggleCommentLike(commentId, comment['is_liked']);
    if (success) {
      setState(() {
        comment['is_liked'] = !comment['is_liked'];
        comment['likes_count'] += comment['is_liked'] ? 1 : -1;
      });
      // AL NO RE-ORDENAR AQUÍ, LOS COMENTARIOS SE QUEDAN EN SU SITIO
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final content = _commentController.text.trim();
    final parentId = _rootParentId;
    final replyTo = _replyingToName;
    _commentController.clear();
    setState(() { _replyingToId = null; _replyingToName = null; _rootParentId = null; });
    final success = await _postService.addComment(widget.postId, content, parentId: parentId, replyToUsername: replyTo);
    if (success) _loadData(); 
  }

  String _formatCaptureDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
      return "${date.day} de ${months[date.month - 1]} de ${date.year}";
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
    if (_post == null) return const Scaffold(body: Center(child: Text("Obra no encontrada")));

    final profile = _post!['profiles'];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool isMe = profile?['id'] == currentUserId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text("Galería", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PERFIL DEL AUTOR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(profile?['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?['display_name'] ?? profile?['username'] ?? "Artista", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("@${profile?['username']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (!isMe)
                          TextButton(
                            onPressed: _toggleFollow,
                            child: Text(
                              _isFollowing ? "Siguiendo" : "Seguir",
                              style: TextStyle(fontWeight: FontWeight.bold, color: _isFollowing ? Colors.grey : theme.primaryColor),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // CABECERA EDITORIAL
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_post!['title'] != null && _post!['title']!.isNotEmpty)
                          Text(
                            _post!['title'],
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5, height: 1.1),
                          ),
                        const SizedBox(height: 8),
                        if (_post!['content'] != null && _post!['content']!.isNotEmpty)
                          Text(
                            _post!['content'],
                            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8), height: 1.5),
                          ),
                        const SizedBox(height: 20),
                        
                        // FICHA TÉCNICA
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMetaRow(Icons.person_outline, "Autor original", _post!['author_name'] ?? "Anónimo"),
                              const SizedBox(height: 10),
                              _buildMetaRow(Icons.calendar_today_outlined, "Fecha de captura", _post!['capture_date'] != null ? _formatCaptureDate(_post!['capture_date']) : "No especificada"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // IMAGEN
                  InteractiveViewer(
                    child: Image.network(_post!['image_url'], width: double.infinity, fit: BoxFit.contain),
                  ),

                  // ACCIONES
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _buildActionButton(
                          _post!['is_liked'] ? Icons.favorite : Icons.favorite_border, 
                          "${_post!['likes_count']}", 
                          _post!['is_liked'] ? Colors.red : Colors.grey,
                          _handleLike
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.ios_share), onPressed: () {}),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("COMENTARIOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String count, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    // Ya no ordenamos aquí, usamos el orden fijo de la lista cargada
    final mainComments = _comments.where((c) => c['parent_id'] == null).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mainComments.length,
      itemBuilder: (context, index) {
        final comment = mainComments[index];
        final String commentId = comment['id'].toString();
        // Las respuestas también mantienen su orden inicial
        final replies = _comments.where((c) => c['parent_id']?.toString() == commentId).toList();

        return Column(
          children: [
            _buildCommentTile(comment, isMain: true),
            ...replies.map((reply) => Padding(padding: const EdgeInsets.only(left: 50), child: _buildCommentTile(reply, isMain: false, rootId: commentId))),
          ],
        );
      },
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, {required bool isMain, String? rootId}) {
    final theme = Theme.of(context);
    final cProfile = comment['profiles'];
    final String commentId = comment['id'].toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundImage: NetworkImage(cProfile?['avatar_url'] ?? ProfileService.defaultAvatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cProfile?['username'] ?? "user", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(comment['content'], style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() { _replyingToId = commentId; _replyingToName = cProfile?['username']; _rootParentId = isMain ? commentId : rootId; }),
                  child: const Text("Responder", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(comment['is_liked'] ? Icons.favorite : Icons.favorite_border, size: 14), 
                color: comment['is_liked'] ? Colors.red : Colors.grey, 
                onPressed: () => _handleCommentLike(comment),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Text("${comment['likes_count'] ?? 0}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToId != null) 
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    Text("Respondiendo a @$_replyingToName", style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() { _replyingToId = null; _replyingToName = null; _rootParentId = null; }),
                      child: const Icon(Icons.close, size: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Escribe un comentario...",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6C63FF), size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
