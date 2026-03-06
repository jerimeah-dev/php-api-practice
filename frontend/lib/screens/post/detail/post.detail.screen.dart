import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/comment/comment.model.dart';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/screens/post/form/post.form.screen.dart';
import 'package:frontend/screens/profile/profile.screen.dart';
import 'package:frontend/services/comment/comment.services.dart';
import 'package:frontend/services/post/post.services.dart';
import 'package:frontend/states/comment/comment.state.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';
import 'package:frontend/widgets/post_author_avatar.dart';
import 'package:frontend/widgets/post_image_grid.dart';
import 'package:frontend/widgets/reaction_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _fbBlue = Color(0xFF1877F2);
const _fbGray = Color(0xFF65676B);

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  static const routePath = '/post/:id';
  static void push(BuildContext ctx, String id) => ctx.push('/post/$id');
  static void go(BuildContext ctx, String id) => ctx.go('/post/$id');

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CommentService.instance.loadForPost(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PostState, PostModel?>(
      selector: (_, s) =>
          s.posts.where((p) => p.id == widget.postId).firstOrNull,
      builder: (context, post, _) {
        if (post == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found')),
          );
        }
        return _PostDetailView(
          post: post,
          commentFocus: _commentFocus,
          postId: widget.postId,
        );
      },
    );
  }
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView({
    required this.post,
    required this.commentFocus,
    required this.postId,
  });

  final PostModel post;
  final FocusNode commentFocus;
  final String postId;

  static const _emojiMap = {
    'Like': '👍', 'Love': '❤️', 'Haha': '😂',
    'Wow':  '😮', 'Sad':  '😢', 'Angry': '😡',
  };
  static const _emojiOrder = ['Like', 'Love', 'Haha', 'Wow', 'Sad', 'Angry'];

  @override
  Widget build(BuildContext context) {
    final isOwner = post.userId == UserState.instance.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => PostFormScreen.pushEdit(context, post),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        color: _fbBlue,
        onRefresh: () => CommentService.instance.loadForPost(postId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Post card ──────────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorRow(context),
                  _buildContent(),
                  if (post.imageUrls.isNotEmpty) _buildImages(context),
                  _buildReactionSummary(context),
                  const Divider(height: 1, indent: 12, endIndent: 12),
                  FullReactionBar(
                    targetType: 'post',
                    targetId: post.id,
                    reactionCounts: post.reactionCounts,
                    userReaction: post.userReaction,
                    onComment: () => commentFocus.requestFocus(),
                  ),
                ],
              ),
            ),

            // ── Comments ───────────────────────────────────────────────────
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              child: _CommentsSection(postId: postId),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: _CommentInput(postId: postId, focusNode: commentFocus),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => ProfileScreen.push(context, post.userId),
            child: PostAuthorAvatar(
                name: post.authorName,
                avatarUrl: post.authorAvatarUrl,
                size: 42),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => ProfileScreen.push(context, post.userId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    post.authorName.isNotEmpty ? post.authorName : 'Anonymous',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Color(0xFF050505)),
                  ),
                  Row(
                    children: [
                      Text(_formatDate(post.createdAt),
                          style: const TextStyle(color: _fbGray, fontSize: 12)),
                      const SizedBox(width: 3),
                      const Icon(Icons.public, size: 12, color: _fbGray),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            style: const TextStyle(
                fontSize: 16, color: Color(0xFF050505), height: 1.5),
          ),
          if (post.updatedAt != post.createdAt) ...[
            const SizedBox(height: 8),
            Text(
              'Edited · ${_formatDate(post.updatedAt)}',
              style: const TextStyle(
                  color: _fbGray, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    return PostImageGrid(
      imageUrls: post.imageUrls,
      borderRadius: BorderRadius.zero,
      onTap: (i) => _openFullscreen(context, i),
    );
  }

  Widget _buildReactionSummary(BuildContext context) {
    final total = post.reactionCounts.values.fold(0, (s, v) => s + v);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          if (total > 0) ...[
            _emojiStack(post.reactionCounts),
            const SizedBox(width: 4),
            Text('$total', style: const TextStyle(color: _fbGray, fontSize: 13)),
          ],
          const Spacer(),
          Selector<CommentState, int>(
            selector: (_, s) => s.comments.length,
            builder: (_, count, __) => count > 0
                ? Text('$count comment${count == 1 ? '' : 's'}',
                    style: const TextStyle(color: _fbGray, fontSize: 13))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _emojiStack(Map<String, int> counts) {
    final shown = _emojiOrder
        .where((t) => (counts[t] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    final top = shown.take(3).toList();
    return SizedBox(
      width: top.length * 16.0 + 6,
      height: 22,
      child: Stack(
        children: top.asMap().entries.map((e) {
          return Positioned(
            left: e.key * 14.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 1, color: Color(0x22000000))],
              ),
              alignment: Alignment.center,
              child: Text(_emojiMap[e.value]!,
                  style: const TextStyle(fontSize: 11)),
            ),
          );
        }).toList(),
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
              child: const Text('Cancel')),
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

  void _openFullscreen(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullscreenGallery(imageUrls: post.imageUrls, initialIndex: index),
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

// ─── Comments section ─────────────────────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Selector<CommentState, (List<CommentModel>, bool, bool)>(
      selector: (_, s) => (s.comments, s.loading, s.hasMore),
      builder: (context, data, _) {
        final (comments, loading, hasMore) = data;
        final topLevel = comments.where((c) => c.parentId == null).toList();
        final replyCount = comments.length - topLevel.length;
        debugPrint('[CommentsSection] topLevel: ${topLevel.length}, replies: $replyCount, hasMore: $hasMore');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              child: Text(
                '${comments.length} Comment${comments.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF050505)),
              ),
            ),
            if (loading && comments.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: _fbBlue)))
            else if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No comments yet. Be the first!',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ...topLevel.map((c) {
                final replies = comments.where((r) => r.parentId == c.id).toList();
                debugPrint('[CommentsSection] comment ${c.id}: ${replies.length} replies');
                return _CommentTile(
                  comment: c,
                  replies: replies,
                  postId: postId,
                  hasMore: hasMore,
                );
              }),
            if (hasMore || (loading && comments.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _fbBlue))
                      : TextButton(
                          onPressed: () => CommentService.instance.loadMore(postId),
                          child: const Text('Load more comments',
                              style: TextStyle(color: _fbBlue, fontWeight: FontWeight.w600)),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile(
      {required this.comment,
      required this.replies,
      required this.postId,
      required this.hasMore});
  final CommentModel comment;
  final List<CommentModel> replies;
  final String postId;
  final bool hasMore;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplyInput = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentRow(
          comment: widget.comment,
          onReply: () => setState(() => _showReplyInput = !_showReplyInput),
        ),
        if (_showReplyInput)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: _InlineReplyInput(
              postId: widget.postId,
              parentId: widget.comment.id,
              onDone: () => setState(() => _showReplyInput = false),
            ),
          ),
        ...widget.replies.map((r) => Padding(
              padding: const EdgeInsets.only(left: 44),
              child: _CommentRow(comment: r),
            )),
        if (widget.hasMore && widget.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 4),
            child: GestureDetector(
              onTap: () => CommentService.instance.loadMore(widget.postId),
              child: const Text(
                'Load more replies',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _fbBlue),
              ),
            ),
          ),
        const Divider(height: 1, indent: 12, endIndent: 12),
      ],
    );
  }
}

class _CommentRow extends StatefulWidget {
  const _CommentRow({required this.comment, this.onReply});
  final CommentModel comment;
  final VoidCallback? onReply;

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  bool _editing = false;
  late final TextEditingController _editCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final text = _editCtrl.text.trim();
    if (text.isEmpty || text == widget.comment.content) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    await CommentService.instance.updateById(widget.comment.id, text);
    if (mounted) setState(() { _editing = false; _saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.comment.userId == UserState.instance.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => ProfileScreen.push(context, widget.comment.userId),
            child: PostAuthorAvatar(
                name: widget.comment.authorName,
                avatarUrl: widget.comment.authorAvatarUrl,
                size: 32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.authorName.isNotEmpty
                            ? widget.comment.authorName
                            : 'Anonymous',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF050505)),
                      ),
                      const SizedBox(height: 2),
                      if (_editing) ...[
                        TextField(
                          controller: _editCtrl,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF050505)),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _saving ? null : () => setState(() {
                                _editing = false;
                                _editCtrl.text = widget.comment.content;
                              }),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _saving ? null : _saveEdit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: _fbBlue,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ] else
                        Text(widget.comment.content,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF050505))),
                    ],
                  ),
                ),
                if (widget.comment.imageUrls.isNotEmpty && !_editing) ...[
                  const SizedBox(height: 6),
                  PostImageGrid(imageUrls: widget.comment.imageUrls),
                ],
                // Action row below bubble
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    children: [
                      Text(_formatDate(widget.comment.createdAt),
                          style: const TextStyle(fontSize: 11, color: _fbGray)),
                      const SizedBox(width: 12),
                      CompactReactionBar(
                        targetType: 'comment',
                        targetId: widget.comment.id,
                        reactionCounts: widget.comment.reactionCounts,
                        userReaction: widget.comment.userReaction,
                      ),
                      if (widget.onReply != null && !_editing) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: widget.onReply,
                          child: const Text('Reply',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _fbGray)),
                        ),
                      ],
                      if (isOwner && !_editing) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            _editing = true;
                            _editCtrl.text = widget.comment.content;
                          }),
                          child: const Icon(Icons.edit_outlined, size: 14, color: _fbGray),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => CommentService.instance.deleteById(widget.comment.id),
                          child: const Icon(Icons.delete_outline, size: 14, color: _fbGray),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InlineReplyInput extends StatefulWidget {
  const _InlineReplyInput(
      {required this.postId, required this.parentId, required this.onDone});
  final String postId;
  final String parentId;
  final VoidCallback onDone;

  @override
  State<_InlineReplyInput> createState() => _InlineReplyInputState();
}

class _InlineReplyInputState extends State<_InlineReplyInput> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    await CommentService.instance.create(
      postId: widget.postId,
      content: text,
      parentId: widget.parentId,
    );
    if (mounted) {
      _ctrl.clear();
      setState(() => _loading = false);
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: const TextStyle(color: _fbGray, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 6),
          _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _fbBlue))
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _submit,
                  color: _fbBlue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
        ],
      ),
    );
  }
}

// ─── Bottom comment input ─────────────────────────────────────────────────────

class _CommentInput extends StatefulWidget {
  const _CommentInput({required this.postId, this.focusNode});
  final String postId;
  final FocusNode? focusNode;

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    await CommentService.instance.create(postId: widget.postId, content: text);
    if (mounted) {
      _ctrl.clear();
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E6EB))),
      ),
      child: Row(
        children: [
          PostAuthorAvatar(
              name: UserState.instance.name,
              avatarUrl: UserState.instance.avatarUrl,
              size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: const TextStyle(color: _fbGray, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 4),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _fbBlue))
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _submit,
                  color: _fbBlue,
                ),
        ],
      ),
    );
  }
}

// ─── Fullscreen image gallery ─────────────────────────────────────────────────

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
                  child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, _, _) => Icon(Icons.broken_image_outlined,
                  size: 64, color: Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}
