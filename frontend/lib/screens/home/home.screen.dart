import 'package:flutter/material.dart';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/screens/auth/login/auth.login.screen.dart';
import 'package:frontend/screens/post/detail/post.detail.screen.dart';
import 'package:frontend/screens/post/form/post.form.screen.dart';
import 'package:frontend/screens/profile/profile.screen.dart';
import 'package:frontend/services/post/post.services.dart';
import 'package:frontend/services/user/user.services.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';
import 'package:frontend/widgets/post_author_avatar.dart';
import 'package:frontend/widgets/post_image_grid.dart';
import 'package:frontend/widgets/reaction_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _fbBlue = Color(0xFF1877F2);
const _fbGray = Color(0xFF65676B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';
  static void go(BuildContext ctx) => ctx.go(routeName);
  static void push(BuildContext ctx) => ctx.push(routeName);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => PostService.instance.loadFeed());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      PostService.instance.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, (String, String, String)>(
      selector: (_, s) => (s.id, s.name, s.avatarUrl),
      builder: (context, user, _) {
        final (id, name, avatarUrl) = user;
        if (id.isEmpty) return const LoginScreen();

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          appBar: _FbAppBar(userId: id, name: name, avatarUrl: avatarUrl),
          body: _PostFeed(
            scrollCtrl: _scrollCtrl,
            name: name,
            avatarUrl: avatarUrl,
          ),
        );
      },
    );
  }
}

// ─── FB-style AppBar ──────────────────────────────────────────────────────────

class _FbAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FbAppBar(
      {required this.userId, required this.name, required this.avatarUrl});

  final String userId;
  final String name;
  final String avatarUrl;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Text(
                'facebook',
                style: TextStyle(
                  color: _fbBlue,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _CircleBtn(icon: Icons.search, onTap: () {}),
              const SizedBox(width: 8),
              _CircleBtn(icon: Icons.notifications_outlined, onTap: () {}),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ProfileScreen.push(context, userId),
                child: PostAuthorAvatar(
                    name: name, avatarUrl: avatarUrl, size: 36),
              ),
              const SizedBox(width: 8),
              _CircleBtn(
                icon: Icons.logout,
                onTap: () {
                  UserService.instance.logout();
                  LoginScreen.go(context);
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFE4E6EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF050505)),
      ),
    );
  }
}

// ─── Feed ─────────────────────────────────────────────────────────────────────

class _PostFeed extends StatelessWidget {
  const _PostFeed({
    required this.scrollCtrl,
    required this.name,
    required this.avatarUrl,
  });

  final ScrollController scrollCtrl;
  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Selector<PostState, (List<PostModel>, bool, bool)>(
      selector: (_, s) => (s.posts, s.loading, s.hasMore),
      builder: (context, data, _) {
        final (posts, loading, hasMore) = data;

        if (loading && posts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _fbBlue));
        }

        return RefreshIndicator(
          color: _fbBlue,
          onRefresh: PostService.instance.loadFeed,
          child: ListView.builder(
            controller: scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 1 + (posts.isEmpty ? 1 : posts.length) + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _CreatePostCard(name: name, avatarUrl: avatarUrl);
              }
              if (posts.isEmpty) return const _EmptyFeed();
              final pi = i - 1;
              if (pi == posts.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: _fbBlue)),
                );
              }
              return _PostCard(post: posts[pi]);
            },
          ),
        );
      },
    );
  }
}

// ─── Create post card ─────────────────────────────────────────────────────────

class _CreatePostCard extends StatelessWidget {
  const _CreatePostCard({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              PostAuthorAvatar(name: name, avatarUrl: avatarUrl, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => PostFormScreen.pushCreate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCDD1D5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "What's on your mind?",
                      style: TextStyle(color: _fbGray, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE4E6EB)),
          Row(
            children: [
              _QuickAction(
                icon: Icons.photo_outlined,
                color: const Color(0xFF45BD62),
                label: 'Photo',
                onTap: () => PostFormScreen.pushCreate(context),
              ),
              _QuickAction(
                icon: Icons.person_add_alt_1_outlined,
                color: _fbBlue,
                label: 'Tag',
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.emoji_emotions_outlined,
                color: const Color(0xFFF7B928),
                label: 'Feeling',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        label: Text(label,
            style: const TextStyle(
                color: Color(0xFF050505),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.article_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No posts yet',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Be the first to share something!',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final PostModel post;

  static const _emojiMap = {
    'Like': '👍',
    'Love': '❤️',
    'Haha': '😂',
    'Wow':  '😮',
    'Sad':  '😢',
    'Angry':'😡',
  };
  static const _emojiOrder = ['Like', 'Love', 'Haha', 'Wow', 'Sad', 'Angry'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildContent(context),
          if (post.imageUrls.isNotEmpty) _buildImages(context),
          _buildReactionSummary(),
          const Divider(height: 1, indent: 12, endIndent: 12),
          FullReactionBar(
            targetType: 'post',
            targetId: post.id,
            reactionCounts: post.reactionCounts,
            userReaction: post.userReaction,
            onComment: () => PostDetailScreen.push(context, post.id),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
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
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 22),
            color: const Color(0xFF050505),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return GestureDetector(
      onTap: () => PostDetailScreen.push(context, post.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Text(
          post.content,
          style: const TextStyle(
              fontSize: 15, color: Color(0xFF050505), height: 1.45),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    return PostImageGrid(
      imageUrls: post.imageUrls,
      borderRadius: BorderRadius.zero,
      onTap: (_) => PostDetailScreen.push(context, post.id),
    );
  }

  Widget _buildReactionSummary() {
    final total = post.reactionCounts.values.fold(0, (s, v) => s + v);
    if (total == 0) return const SizedBox(height: 4);

    final topTypes = _emojiOrder
        .where((t) => (post.reactionCounts[t] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (post.reactionCounts[b] ?? 0).compareTo(post.reactionCounts[a] ?? 0));
    final shown = topTypes.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: shown.length * 16.0 + 6,
            height: 22,
            child: Stack(
              children: shown.asMap().entries.map((e) {
                return Positioned(
                  left: e.key * 14.0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(blurRadius: 1, color: Color(0x22000000))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(_emojiMap[e.value]!,
                        style: const TextStyle(fontSize: 11)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 4),
          Text('$total', style: const TextStyle(color: _fbGray, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
