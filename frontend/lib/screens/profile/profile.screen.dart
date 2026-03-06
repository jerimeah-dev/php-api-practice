import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/models/user/user.model.dart';
import 'package:frontend/screens/post/detail/post.detail.screen.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;

  static const String routeName = '/profile/:id';
  static void push(BuildContext ctx, String id) => ctx.push('/profile/$id');
  static void go(BuildContext ctx, String id) => ctx.go('/profile/$id');

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  UserModel? _profileUser;
  bool _loadingUser = true;

  // Profile tracks only IDs; post data lives in PostState for instant reactions
  final List<String> _postIds = [];
  bool _loadingPosts = false;
  bool _hasMore = true;

  bool get _isOwn => widget.userId == UserState.instance.id;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser({bool forceRefresh = false}) async {
    // Own profile: use cached UserState immediately
    if (_isOwn && !forceRefresh) {
      final stateUser = UserState.instance.user;
      if (stateUser != null) {
        setState(() { _profileUser = stateUser; _loadingUser = false; });
        if (_postIds.isEmpty) _resetPosts();
        return;
      }
    }

    // Check service cache
    final cached = UserService.instance.getCached(widget.userId);
    if (cached != null && !forceRefresh) {
      setState(() { _profileUser = cached; _loadingUser = false; });
      if (_postIds.isEmpty) _resetPosts();
      return;
    }

    if (!forceRefresh) setState(() => _loadingUser = true);
    final user = await UserService.instance.fetchAndCache(widget.userId);
    if (mounted) {
      setState(() { _profileUser = user; _loadingUser = false; });
      if (_postIds.isEmpty) _resetPosts();
    }
  }

  Future<void> _refreshAll() async {
    await _loadUser(forceRefresh: true);
    await _resetPosts();
  }

  Future<void> _resetPosts() async {
    setState(() {
      _postIds.clear();
      _hasMore = true;
    });
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (_loadingPosts || !_hasMore) return;
    setState(() => _loadingPosts = true);

    final more = await PostService.instance.fetchPageAndUpsert(
      offset: _postIds.length,
      authorId: widget.userId,
    );

    if (mounted) {
      final knownIds = _postIds.toSet();
      final newIds = PostState.instance.posts
          .where((p) => p.userId == widget.userId && !knownIds.contains(p.id))
          .map((p) => p.id)
          .toList();
      setState(() {
        _postIds.addAll(newIds);
        _hasMore = more;
        _loadingPosts = false;
      });
    }
  }

  Future<void> _setProfilePic(int index) async {
    final user = _profileUser;
    if (user == null || index == 0 || index >= user.profileImages.length) return;
    final imageUrl = user.profileImages[index].url;
    await UserService.instance.setProfilePic(imageUrl);
    await _loadUser(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser && _profileUser == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator(color: _fbBlue)));
    }
    if (_profileUser == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('User not found')));
    }

    final user = _profileUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
            user.name.isNotEmpty
                ? user.name
                : (user.email.isNotEmpty ? user.email.split('@')[0] : 'Profile'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: _fbBlue,
        onRefresh: _refreshAll,
        child: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _CoverAndAvatar(
                      user: user,
                      isOwn: _isOwn,
                      onSetProfilePic: _setProfilePic,
                    ),
                    _ProfileInfo(
                      user: user,
                      isOwn: _isOwn,
                      onEdit: () => _showEditProfile(context, user),
                    ),
                    const SizedBox(height: 4),
                    TabBar(
                      controller: _tabCtrl,
                      tabs: const [Tab(text: 'Posts'), Tab(text: 'Photos')],
                      indicatorColor: _fbBlue,
                      labelColor: _fbBlue,
                      unselectedLabelColor: _fbGray,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _PostsTab(
                postIds: _postIds,
                loading: _loadingPosts,
                hasMore: _hasMore,
                onLoadMore: _loadPosts,
              ),
              _PhotosTab(
                images: user.profileImages,
                isOwn: _isOwn,
                onSetProfilePic: _setProfilePic,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _EditProfileSheet(
          user: user, onSaved: () => _loadUser(forceRefresh: true)),
    );
  }
}

// ─── Cover photo + avatar ─────────────────────────────────────────────────────

class _CoverAndAvatar extends StatelessWidget {
  const _CoverAndAvatar({
    required this.user,
    required this.isOwn,
    required this.onSetProfilePic,
  });

  final UserModel user;
  final bool isOwn;
  final Future<void> Function(int index) onSetProfilePic;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Cover photo: coverImages[0] → avatarUrl → placeholder color
        Container(
          height: 180,
          width: double.infinity,
          color: const Color(0xFF8B9DC3),
          child: () {
            final coverUrl = user.coverImages.isNotEmpty
                ? user.coverImages[0].url
                : user.avatarUrl;
            return coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: const Color(0xFF8B9DC3)),
                    errorWidget: (_, _, _) =>
                        Container(color: const Color(0xFF8B9DC3)),
                  )
                : null;
          }(),
        ),
        // Avatar overlapping the cover bottom
        Positioned(
          bottom: -44,
          child: GestureDetector(
            onTap: user.profileImages.isEmpty
                ? null
                : () => _openPhotoViewer(context, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: PostAuthorAvatar(
                  name: user.name, avatarUrl: user.avatarUrl, size: 88),
            ),
          ),
        ),
      ],
    );
  }

  void _openPhotoViewer(BuildContext context, int initialIndex) {
    final urls = user.profileImages.map((p) => p.url).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(
          urls: urls,
          initialIndex: initialIndex,
          isOwn: isOwn,
          onSetProfilePic: onSetProfilePic,
        ),
      ),
    );
  }
}

// ─── Name + info + edit button ────────────────────────────────────────────────

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo(
      {required this.user, required this.isOwn, required this.onEdit});

  final UserModel user;
  final bool isOwn;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 8),
      child: Column(
        children: [
          Text(
            user.name.isNotEmpty
                ? user.name
                : (user.email.isNotEmpty
                    ? user.email[0].toUpperCase()
                    : '?'),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF050505)),
          ),
          const SizedBox(height: 2),
          Text(user.email,
              style: const TextStyle(color: _fbGray, fontSize: 13)),
          Text(
            'Joined ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            style: const TextStyle(color: _fbGray, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (isOwn)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onEdit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE4E6EB),
                  foregroundColor: const Color(0xFF050505),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit profile',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Posts tab ────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.postIds,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<String> postIds;
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (loading && postIds.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _fbBlue));
    }
    if (postIds.isEmpty) {
      return const Center(
          child: Text('No posts yet',
              style: TextStyle(color: _fbGray, fontSize: 15)));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent * 0.8) onLoadMore();
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: postIds.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == postIds.length) {
            return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: _fbBlue)));
          }
          return _ProfilePostCard(postId: postIds[i]);
        },
      ),
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  const _ProfilePostCard({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Selector<PostState, PostModel?>(
      selector: (_, s) => s.posts.cast<PostModel?>().firstWhere(
            (p) => p?.id == postId,
            orElse: () => null,
          ),
      builder: (context, post, _) {
        if (post == null) return const SizedBox.shrink();
        return Container(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => PostDetailScreen.push(context, post.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(post.createdAt),
                          style: const TextStyle(fontSize: 12, color: _fbGray)),
                      const SizedBox(height: 6),
                      if (post.title.isNotEmpty) ...[
                        Text(post.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF050505))),
                        const SizedBox(height: 4),
                      ],
                      Text(post.content,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF050505)),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (post.imageUrls.isNotEmpty)
                  PostImageGrid(
                      imageUrls: post.imageUrls, borderRadius: BorderRadius.zero),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      const Divider(height: 1),
                      FullReactionBar(
                        targetType: 'post',
                        targetId: post.id,
                        reactionCounts: post.reactionCounts,
                        userReaction: post.userReaction,
                        onComment: () => PostDetailScreen.push(context, post.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

// ─── Photos tab ───────────────────────────────────────────────────────────────

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({
    required this.images,
    required this.isOwn,
    required this.onSetProfilePic,
  });

  final List<ProfileImageModel> images;
  final bool isOwn;
  final Future<void> Function(int index) onSetProfilePic;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
          child: Text('No photos yet',
              style: TextStyle(color: _fbGray, fontSize: 15)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final img = images[i];
        return GestureDetector(
          onTap: () => _openViewer(context, i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: img.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: Colors.grey[200]),
                errorWidget: (_, _, _) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey)),
              ),
              if (i == 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: _fbBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openViewer(BuildContext context, int index) {
    final urls = images.map((img) => img.url).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(
          urls: urls,
          initialIndex: index,
          isOwn: isOwn,
          onSetProfilePic: onSetProfilePic,
        ),
      ),
    );
  }
}

// ─── Photo viewer (fullscreen + set as profile pic) ───────────────────────────

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({
    required this.urls,
    required this.initialIndex,
    this.isOwn = false,
    this.onSetProfilePic,
  });

  final List<String> urls;
  final int initialIndex;
  final bool isOwn;
  final Future<void> Function(int index)? onSetProfilePic;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _ctrl;
  late int _current;
  bool _setting = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _setAsProfilePic() async {
    if (_setting) return;
    setState(() => _setting = true);
    await widget.onSetProfilePic!(_current);
    if (mounted) {
      setState(() => _setting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentProfilePic = _current == 0;
    final showSetBtn =
        widget.isOwn && !isCurrentProfilePic && widget.onSetProfilePic != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
              placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, _, _) => Icon(Icons.broken_image_outlined,
                  size: 64, color: Colors.grey.shade600),
            ),
          ),
        ),
      ),
      bottomNavigationBar: showSetBtn
          ? SafeArea(
              child: Container(
                color: const Color(0xFF1C1C1C),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _setting
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : GestureDetector(
                        onTap: _setAsProfilePic,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_pin, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Set as Profile Picture',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            )
          : widget.isOwn && isCurrentProfilePic
              ? SafeArea(
                  child: Container(
                    color: const Color(0xFF1C1C1C),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_pin, color: _fbBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Current Profile Picture',
                          style: TextStyle(
                            color: _fbBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
    );
  }
}

// ─── Edit profile sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSaved});
  final UserModel user;
  final VoidCallback onSaved;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late List<ProfileImageModel> _images;
  late List<ProfileImageModel> _coverImages;
  final _urlCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.user.name);
    _images      = List.from(widget.user.profileImages);
    _coverImages = List.from(widget.user.coverImages);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _coverUrlCtrl.dispose();
    super.dispose();
  }

  void _addImage() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _images.add(ProfileImageModel(url: url, createdAt: DateTime.now()));
      _urlCtrl.clear();
    });
  }

  void _addCoverImage() {
    final url = _coverUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _coverImages.add(ProfileImageModel(url: url, createdAt: DateTime.now()));
      _coverUrlCtrl.clear();
    });
  }

  void _setAsPrimary(int i) {
    if (i == 0) return;
    setState(() {
      final img = _images.removeAt(i);
      _images.insert(0, img);
    });
  }

  void _setCoverAsPrimary(int i) {
    if (i == 0) return;
    setState(() {
      final img = _coverImages.removeAt(i);
      _coverImages.insert(0, img);
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    Navigator.pop(context);
    await UserService.instance.updateProfile(
      name: _nameCtrl.text.trim(),
      profileImages: _images,
      coverImages: _coverImages,
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Edit Profile',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF050505))),
              const Spacer(),
              FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: _fbBlue),
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _fbBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Profile Photos',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF050505))),
              const SizedBox(width: 8),
              Text('(tap ★ to set as profile picture)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addImage,
                style: FilledButton.styleFrom(backgroundColor: _fbBlue),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _images.length,
              itemBuilder: (context, i) => _ImageListTile(
                img: _images[i],
                isPrimary: i == 0,
                primaryLabel: 'Profile Pic',
                onSetPrimary: () => _setAsPrimary(i),
                onDelete: () => setState(() => _images.removeAt(i)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Cover Photos',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF050505))),
              const SizedBox(width: 8),
              Text('(tap ★ to set as cover)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coverUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addCoverImage,
                style: FilledButton.styleFrom(backgroundColor: _fbBlue),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _coverImages.length,
              itemBuilder: (context, i) => _ImageListTile(
                img: _coverImages[i],
                isPrimary: i == 0,
                primaryLabel: 'Cover',
                onSetPrimary: () => _setCoverAsPrimary(i),
                onDelete: () => setState(() => _coverImages.removeAt(i)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable image list tile for edit sheet ──────────────────────────────────

class _ImageListTile extends StatelessWidget {
  const _ImageListTile({
    required this.img,
    required this.isPrimary,
    required this.primaryLabel,
    required this.onSetPrimary,
    required this.onDelete,
  });

  final ProfileImageModel img;
  final bool isPrimary;
  final String primaryLabel;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 44,
          height: 44,
          child: CachedNetworkImage(
            imageUrl: img.url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: Colors.grey[200]),
            errorWidget: (_, _, _) =>
                const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
      title: Row(
        children: [
          if (isPrimary)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _fbBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(primaryLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          Expanded(
            child: Text(img.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: isPrimary ? 'Current $primaryLabel' : 'Set as $primaryLabel',
            icon: Icon(
              isPrimary ? Icons.star : Icons.star_outline,
              color: isPrimary ? Colors.amber : Colors.grey,
              size: 20,
            ),
            onPressed: isPrimary ? null : onSetPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
