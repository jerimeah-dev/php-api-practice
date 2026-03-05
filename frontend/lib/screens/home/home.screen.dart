import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:frontend/widgets/reaction_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';
  static Function(BuildContext ctx) push = (ctx) => ctx.push(routeName);
  static Function(BuildContext ctx) go = (ctx) => ctx.go(routeName);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PostService.instance.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, String>(
      selector: (_, state) => state.id,
      builder: (context, id, _) {
        if (id.isEmpty) return const LoginScreen();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => ProfileScreen.push(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  UserService.instance.logout();
                  LoginScreen.go(context);
                },
              ),
            ],
          ),
          body: const _PostFeed(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => PostFormScreen.pushCreate(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('New Post'),
          ),
        );
      },
    );
  }
}

class _PostFeed extends StatelessWidget {
  const _PostFeed();

  @override
  Widget build(BuildContext context) {
    return Selector<PostState, (List<PostModel>, bool)>(
      selector: (_, s) => (s.posts, s.loading),
      builder: (context, data, _) {
        final (posts, loading) = data;

        if (loading && posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share something!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: PostService.instance.loadAll,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _PostCard(post: posts[i]),
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => PostDetailScreen.push(context, post.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                PostAuthorAvatar(name: post.authorName, avatarUrl: post.authorAvatarUrl, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName.isNotEmpty ? post.authorName : 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Content preview
            Text(
              post.content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Image grid (FB-style)
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              _PostImageGrid(imageUrls: post.imageUrls),
            ],

            const SizedBox(height: 10),
            CompactReactionBar(post: post),
            const SizedBox(height: 6),

            // Read more
            Text(
              'Read more',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

/// FB-style image grid:
/// 1 image  → full width
/// 2 images → side by side
/// 3 images → 1 large left + 2 stacked right
/// 4+ images → 2×2 grid, last cell shows "+N more" overlay
class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({required this.imageUrls});
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls;
    const radius = BorderRadius.all(Radius.circular(8));

    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: _gridImage(urls[0], height: 220),
      );
    }

    if (urls.length == 2) {
      return ClipRRect(
        borderRadius: radius,
        child: Row(
          children: [
            Expanded(child: _gridImage(urls[0], height: 180)),
            const SizedBox(width: 2),
            Expanded(child: _gridImage(urls[1], height: 180)),
          ],
        ),
      );
    }

    if (urls.length == 3) {
      return ClipRRect(
        borderRadius: radius,
        child: Row(
          children: [
            Expanded(flex: 3, child: _gridImage(urls[0], height: 200)),
            const SizedBox(width: 2),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _gridImage(urls[1], height: 99),
                  const SizedBox(height: 2),
                  _gridImage(urls[2], height: 99),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ images: 2×2 grid, last cell has overlay
    final shown = urls.take(4).toList();
    final extra = urls.length - 4;
    return ClipRRect(
      borderRadius: radius,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _gridImage(shown[0], height: 140)),
              const SizedBox(width: 2),
              Expanded(child: _gridImage(shown[1], height: 140)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: _gridImage(shown[2], height: 140)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    _gridImage(shown[3], height: 140),
                    if (extra > 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+$extra',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gridImage(String url, {required double height}) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        height: height,
        color: Colors.grey.shade200,
      ),
      errorWidget: (_, _, _) => Container(
        height: height,
        color: Colors.grey.shade100,
        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
      ),
    );
  }
}

