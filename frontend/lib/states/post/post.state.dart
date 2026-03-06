import 'package:flutter/foundation.dart';
import 'package:frontend/models/post/post.model.dart';

class PostState extends ChangeNotifier {
  static final instance = PostState._();
  PostState._();

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  bool _loading = false;
  bool get loading => _loading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _total = 0;
  int get total => _total;

  // Reaction snapshot for optimistic UI rollback
  Map<String, dynamic>? _snapshot;
  String? _snapshotId;

  void setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void setPosts(List<PostModel> posts, {required int total, required bool hasMore}) {
    _posts   = posts;
    _total   = total;
    _hasMore = hasMore;
    debugPrint('[PostState] posts: ${_posts.length} (total: $_total, hasMore: $_hasMore)');
    notifyListeners();
  }

  void appendPosts(List<PostModel> page, {required int total, required bool hasMore}) {
    _posts   = [..._posts, ...page];
    _total   = total;
    _hasMore = hasMore;
    debugPrint('[PostState] posts: ${_posts.length} (total: $_total, hasMore: $_hasMore)');
    notifyListeners();
  }

  /// Upsert posts into state without clearing the list.
  /// Used by profile screen to add/update posts while preserving global feed.
  void upsertPosts(List<PostModel> page) {
    final existing = <String, int>{};
    for (var i = 0; i < _posts.length; i++) {
      existing[_posts[i].id] = i;
    }
    final updated = List<PostModel>.from(_posts);
    final appended = <PostModel>[];
    for (final p in page) {
      final idx = existing[p.id];
      if (idx != null) {
        updated[idx] = p;
      } else {
        appended.add(p);
      }
    }
    _posts = [...updated, ...appended];
    debugPrint('[PostState] posts (upsert): ${_posts.length}');
    notifyListeners();
  }

  void clearPosts() {
    _posts   = [];
    _total   = 0;
    _hasMore = true;
    notifyListeners();
  }

  void addPost(PostModel post) {
    _posts = [post, ..._posts];
    _total++;
    notifyListeners();
  }

  void updatePost(PostModel post) {
    _posts = _posts.map((p) => p.id == post.id ? post : p).toList();
    notifyListeners();
  }

  void removePost(String id) {
    _posts = _posts.where((p) => p.id != id).toList();
    if (_total > 0) _total--;
    notifyListeners();
  }

  void applyOptimisticReaction(String postId, String type) {
    final post = _posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) return;
    _snapshotId = postId;
    _snapshot   = {'rc': post.reactionCounts, 'ur': post.userReaction};

    final counts = Map<String, int>.from(post.reactionCounts);
    String? newReaction;
    if (post.userReaction == type) {
      counts[type] = (counts[type] ?? 1) - 1;
      if ((counts[type] ?? 0) <= 0) counts.remove(type);
      newReaction = null;
    } else {
      if (post.userReaction != null) {
        final old = post.userReaction!;
        counts[old] = (counts[old] ?? 1) - 1;
        if ((counts[old] ?? 0) <= 0) counts.remove(old);
      }
      counts[type] = (counts[type] ?? 0) + 1;
      newReaction = type;
    }
    updatePost(post.copyWithReactions(reactionCounts: counts, userReaction: newReaction));
  }

  void applyReactionResult(String postId, Map<String, int> reactionCounts, String? userReaction) {
    _snapshot = null;
    final post = _posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) return;
    updatePost(post.copyWithReactions(reactionCounts: reactionCounts, userReaction: userReaction));
  }

  void rollbackReaction(String postId) {
    if (_snapshot == null || _snapshotId != postId) return;
    final post = _posts.where((p) => p.id == postId).firstOrNull;
    if (post != null) {
      updatePost(post.copyWithReactions(
        reactionCounts: _snapshot!['rc'] as Map<String, int>,
        userReaction:   _snapshot!['ur'] as String?,
      ));
    }
    _snapshot = null;
  }
}
