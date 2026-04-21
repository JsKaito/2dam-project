import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  
  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _isLoading = true;
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
    
    if (mounted) {
      setState(() {
        _post = postData;
        _comments = commentsData;
        _isLoading = false;
      });
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
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final content = _commentController.text.trim();
    final parentId = _rootParentId;
    final replyTo = _replyingToName;
    
    _commentController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
      _rootParentId = null;
    });

    final success = await _postService.addComment(
      widget.postId, 
      content, 
      parentId: parentId, 
      replyToUsername: replyTo
    );
    
    if (success) {
      _loadData(); 
    }
  }

  void _sharePost() {
    final String url = "${Uri.base.origin}/post/${widget.postId}";
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enlace copiado al portapapeles")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
    if (_post == null) return const Scaffold(body: Center(child: Text("Publicación no encontrada")));

    final profile = _post!['profiles'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Publicación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(profile?['avatar_url'] ?? ProfileService.defaultAvatarUrl),
                    ),
                    title: Row(
                      children: [
                        Text(profile?['display_name'] ?? profile?['username'] ?? "Artista", style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (profile?['is_verified'] ?? false) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                        ],
                      ],
                    ),
                    subtitle: Text("@${profile?['username']}"),
                  ),
                  Image.network(_post!['image_url'], width: double.infinity, fit: BoxFit.contain),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_post!['is_liked'] ? Icons.favorite : Icons.favorite_border),
                          color: _post!['is_liked'] ? Colors.red : Colors.white,
                          onPressed: _handleLike,
                        ),
                        const SizedBox(width: 4),
                        Text("${_post!['likes_count']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        const Icon(Icons.chat_bubble_outline),
                        const SizedBox(width: 4),
                        Text("${_post!['comments_count']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.share_outlined), onPressed: _sharePost),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white),
                        children: [
                          TextSpan(text: "${profile?['username']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: _post!['content']),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32, color: Color(0xFF2A2A2A)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Comentarios", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildCommentsList() {
    final mainComments = _comments.where((c) => c['parent_id'] == null).toList();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mainComments.length,
      itemBuilder: (context, index) {
        final comment = mainComments[index];
        final String commentId = comment['id'].toString();
        final replies = _comments.where((c) => c['parent_id']?.toString() == commentId).toList();
        
        return Column(
          children: [
            _buildCommentTile(comment, isMain: true),
            ...replies.map((reply) => Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: _buildCommentTile(reply, isMain: false, rootId: commentId),
            )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, {required bool isMain, String? rootId}) {
    final cProfile = comment['profiles'];
    final String commentId = comment['id'].toString();
    final String? replyTo = comment['reply_to_username'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isMain ? 16 : 12,
            backgroundImage: NetworkImage(cProfile?['avatar_url'] ?? ProfileService.defaultAvatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(cProfile?['username'] ?? "user", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (cProfile?['is_verified'] ?? false) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 12),
                    ],
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    children: [
                      if (replyTo != null) ...[
                        TextSpan(text: "@$replyTo ", style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                      ],
                      TextSpan(text: comment['content']),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text("hace un momento", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToId = commentId;
                          _replyingToName = cProfile?['username'];
                          _rootParentId = isMain ? commentId : rootId;
                        });
                      },
                      child: const Text("Responder", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(comment['is_liked'] ? Icons.favorite : Icons.favorite_border, size: 14),
                color: comment['is_liked'] ? Colors.red : Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _handleCommentLike(comment),
              ),
              const SizedBox(height: 2),
              Text("${comment['likes_count']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        left: 16,
        right: 16,
        top: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text("Respondiendo a @$_replyingToName", style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF))),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Añade un comentario...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                onPressed: _submitComment,
                child: const Text("Publicar", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
