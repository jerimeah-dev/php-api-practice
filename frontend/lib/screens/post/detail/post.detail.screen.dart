import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/screens/post/form/post.form.screen.dart';
import 'package:frontend/services/post/post.services.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  static const routePath = '/post/:id';
  static void push(BuildContext ctx, String id) => ctx.push('/post/$id');
  static void go(BuildContext ctx, String id) => ctx.go('/post/$id');

  @override
  Widget build(BuildContext context) {
    return Selector<PostState, PostModel?>(
      selector: (_, s) => s.posts.where((p) => p.id == postId).firstOrNull,
      builder: (context, post, _) {
        if (post == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found')),
          );
        }
        return _PostDetailView(post: post);
      },
    );
  }
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView({required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final isOwner = post.userId == UserState.instance.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => PostFormScreen.pushEdit(context, post),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width image(s) at top
            if (post.imageUrls.isNotEmpty)
              _ImageGallery(imageUrls: post.imageUrls),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  Row(
                    children: [
                      _AuthorAvatar(name: post.authorName, size: 40),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName.isNotEmpty
                                ? post.authorName
                                : 'Anonymous',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          Text(
                            _formatDate(post.createdAt),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Text(
                    post.content,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF333333)),
                  ),

                  if (post.updatedAt != post.createdAt) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Edited ${_formatDate(post.updatedAt)}',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await PostService.instance.deleteById(post.id);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Image gallery — horizontal scroll with tap-to-fullscreen
// ---------------------------------------------------------------------------

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.imageUrls});
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return _tappableImage(context, imageUrls.first, 0, height: 280);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: imageUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _tappableImage(context, imageUrls[i], i,
                    width: 200, height: 196, rounded: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            '${imageUrls.length} photos',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _tappableImage(
    BuildContext context,
    String url,
    int index, {
    double? width,
    double? height,
    bool rounded = false,
  }) {
    Widget img = CachedNetworkImage(
      imageUrl: url,
      width: width ?? double.infinity,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: Icon(Icons.broken_image_outlined,
            size: 40, color: Colors.grey.shade400),
      ),
    );

    if (rounded) img = ClipRRect(borderRadius: BorderRadius.circular(10), child: img);

    return GestureDetector(
      onTap: () => _openFullscreen(context, index),
      child: img,
    );
  }

  void _openFullscreen(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullscreenGallery(imageUrls: imageUrls, initialIndex: index),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery(
      {required this.imageUrls, required this.initialIndex});
  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.imageUrls.length > 1
            ? Text('${_current + 1} / ${widget.imageUrls.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[i],
              fit: BoxFit.contain,
              placeholder: (_, _) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, _, _) => Icon(Icons.broken_image_outlined,
                  size: 64, color: Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final color = _colorFromName(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    const colors = [
      Color(0xFF1A73E8),
      Color(0xFF34A853),
      Color(0xFFEA4335),
      Color(0xFFFBBC05),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFFF5722),
      Color(0xFF607D8B),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
