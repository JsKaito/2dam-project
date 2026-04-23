import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:artists_alley/services/profile_service.dart';
import 'package:artists_alley/services/post_service.dart';
import 'package:artists_alley/navigation_wrapper.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String handle; 
  final String time;
  final String? title;
  final String content; 
  final String imageUrl;
  final String? profileImageUrl;
  final int likes;
  final int comments;
  final String userId;
  final String? postId;
  final bool isVerified;
  final bool isLiked;
  final String? authorName;
  final String? captureDate;

  const PostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.time,
    this.title,
    required this.content,
    required this.imageUrl,
    this.profileImageUrl,
    required this.likes,
    required this.comments,
    required this.userId,
    this.postId,
    this.isVerified = false,
    this.isLiked = false,
    this.authorName,
    this.captureDate,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  
  late bool _liked;
  late int _likesCount;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _likesCount = widget.likes;
    _checkStatus();
  }

  void _checkStatus() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;
    _isMe = myId == widget.userId;
  }

  Future<void> _handleLike() async {
    if (widget.postId == null) return;
    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });
    final success = await _postService.toggleLike(widget.postId!, !_liked);
    if (!success && mounted) {
      setState(() {
        _liked = !_liked;
        _likesCount += _liked ? 1 : -1;
      });
    }
  }

  void _openDetails() {
    if (widget.postId != null) {
      // Usamos el NavigationWrapper para mostrar el post sin romper la pila de navegación
      NavigationWrapper.navigationKey.currentState?.showPost(widget.postId!);
    }
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
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  final cleanHandle = widget.handle.startsWith('@') ? widget.handle.substring(1) : widget.handle;
                  // Si el perfil que pulso es el mío, voy a mi pestaña de perfil
                  if (_isMe) {
                    NavigationWrapper.navigationKey.currentState?.setIndex(4);
                  } else {
                    Navigator.pushNamed(context, '/user/$cleanHandle');
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(widget.profileImageUrl!) 
                      : const NetworkImage(ProfileService.defaultAvatarUrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (widget.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 12),
                        ],
                      ],
                    ),
                    Text("${widget.handle} · ${widget.time}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openDetails,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, height: 1.3),
                    children: [
                      if (widget.title != null && widget.title!.isNotEmpty)
                        TextSpan(text: "\"${widget.title}\" ", style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      if (widget.content.isNotEmpty) ...[
                        if (widget.title != null && widget.title!.isNotEmpty)
                          const TextSpan(text: "- "),
                        TextSpan(text: widget.content),
                      ],
                    ],
                  ),
                ),
                if ((widget.authorName != null && widget.authorName!.isNotEmpty) || widget.captureDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 10),
                    child: Text(
                      "${widget.authorName ?? ''}${widget.captureDate != null && widget.captureDate!.isNotEmpty ? ' · ${_formatCaptureDate(widget.captureDate)}' : ''}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                if (widget.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(widget.imageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: _handleLike,
                      child: Row(
                        children: [
                          Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 20, color: _liked ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text("$_likesCount", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
