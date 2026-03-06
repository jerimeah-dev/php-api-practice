import 'package:flutter/foundation.dart';
import 'package:frontend/models/comment/comment.model.dart';

class CommentState extends ChangeNotifier {
  static final instance = CommentState._();
  CommentState._();

  List<CommentModel> _comments = [];
  List<CommentModel> get comments => _comments;

  bool _loading = false;
  bool get loading => _loading;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  Map<String, dynamic>? _snapshot;
  String? _snapshotId;

  void setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void setComments(List<CommentModel> comments, {required bool hasMore}) {
    _comments = comments;
    _hasMore  = hasMore;
    debugPrint('[CommentState] comments: ${_comments.length} (hasMore: $_hasMore)');
    notifyListeners();
  }

  void appendComments(List<CommentModel> page, {required bool hasMore}) {
    _comments = [..._comments, ...page];
    _hasMore  = hasMore;
    debugPrint('[CommentState] comments: ${_comments.length} (hasMore: $_hasMore)');
    notifyListeners();
  }

  void clearComments() {
    _comments = [];
    _hasMore  = false;
    notifyListeners();
  }

  void addComment(CommentModel comment) {
    _comments = [..._comments, comment];
    notifyListeners();
  }

  void updateComment(CommentModel comment) {
    _comments = _comments.map((c) => c.id == comment.id ? comment : c).toList();
    notifyListeners();
  }

  void removeComment(String id) {
    _comments = _comments.where((c) => c.id != id && c.parentId != id).toList();
    notifyListeners();
  }

  void applyOptimisticReaction(String commentId, String type) {
    final comment = _comments.where((c) => c.id == commentId).firstOrNull;
    if (comment == null) return;
    _snapshotId = commentId;
    _snapshot   = {'rc': comment.reactionCounts, 'ur': comment.userReaction};

    final counts = Map<String, int>.from(comment.reactionCounts);
    String? newReaction;
    if (comment.userReaction == type) {
      counts[type] = (counts[type] ?? 1) - 1;
      if ((counts[type] ?? 0) <= 0) counts.remove(type);
      newReaction = null;
    } else {
      if (comment.userReaction != null) {
        final old = comment.userReaction!;
        counts[old] = (counts[old] ?? 1) - 1;
        if ((counts[old] ?? 0) <= 0) counts.remove(old);
      }
      counts[type] = (counts[type] ?? 0) + 1;
      newReaction = type;
    }
    updateComment(comment.copyWithReactions(reactionCounts: counts, userReaction: newReaction));
  }

  void applyReactionResult(String commentId, Map<String, int> reactionCounts, String? userReaction) {
    _snapshot = null;
    final comment = _comments.where((c) => c.id == commentId).firstOrNull;
    if (comment == null) return;
    updateComment(comment.copyWithReactions(reactionCounts: reactionCounts, userReaction: userReaction));
  }

  void rollbackReaction(String commentId) {
    if (_snapshot == null || _snapshotId != commentId) return;
    final comment = _comments.where((c) => c.id == commentId).firstOrNull;
    if (comment != null) {
      updateComment(comment.copyWithReactions(
        reactionCounts: _snapshot!['rc'] as Map<String, int>,
        userReaction:   _snapshot!['ur'] as String?,
      ));
    }
    _snapshot = null;
  }
}
