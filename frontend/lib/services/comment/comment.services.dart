import 'package:frontend/models/comment/comment.model.dart';
import 'package:frontend/repositories/comment/comment.repository.dart';
import 'package:frontend/states/comment/comment.state.dart';
import 'package:frontend/states/user/user.state.dart';

class CommentService {
  static final instance = CommentService._();
  CommentService._();

  final _repo      = CommentRepository.instance;
  final _state     = CommentState.instance;
  final _userState = UserState.instance;

  static const int _pageSize = 5;

  Future<void> loadForPost(String postId) async {
    _state.clearComments();
    _state.setLoading(true);
    await _fetchPage(postId: postId, offset: 0, replace: true);
    // Auto-load one more page so replies split across pages are visible immediately
    if (_state.hasMore) {
      await _fetchPage(postId: postId, offset: _state.comments.length, replace: false);
    }
    _state.setLoading(false);
  }

  Future<void> loadMore(String postId) async {
    if (_state.loading || !_state.hasMore) return;
    _state.setLoading(true);
    await _fetchPage(postId: postId, offset: _state.comments.length, replace: false);
    _state.setLoading(false);
  }

  Future<void> _fetchPage({
    required String postId,
    required int offset,
    required bool replace,
  }) async {
    final res = await _repo.list(
      postId:   postId,
      viewerId: _userState.id,
      limit:    _pageSize,
      offset:   offset,
    );
    if (res['status'] == 'success') {
      final data     = res['data'] as Map<String, dynamic>;
      final hasMore  = data['hasMore'] as bool;
      final comments = (data['comments'] as List? ?? [])
          .map((e) => _parseComment(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (replace) {
        _state.setComments(comments, hasMore: hasMore);
      } else {
        _state.appendComments(comments, hasMore: hasMore);
      }
    }
  }

  Future<CommentModel?> create({
    required String postId,
    required String content,
    String? parentId,
    List<String>? imageUrls,
  }) async {
    final res = await _repo.create(
      userId:    _userState.id,
      postId:    postId,
      content:   content,
      parentId:  parentId,
      imageUrls: imageUrls,
    );
    if (res['status'] != 'success' || res['data']?['comment'] == null) return null;
    final comment = _parseComment(Map<String, dynamic>.from(res['data']['comment']));
    _state.addComment(comment);
    return comment;
  }

  Future<CommentModel?> updateById(String id, String content) async {
    final res = await _repo.updateById(id: id, content: content, imageUrls: []);
    if (res['status'] != 'success' || res['data']?['comment'] == null) return null;
    final comment = _parseComment(Map<String, dynamic>.from(res['data']['comment']));
    _state.updateComment(comment);
    return comment;
  }

  Future<bool> deleteById(String id) async {
    final res = await _repo.deleteById(id);
    if (res['status'] == 'success') {
      _state.removeComment(id);
      return true;
    }
    return false;
  }

  CommentModel _parseComment(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final rc  = map['reactionCounts'];
    if (rc == null || rc is List) map['reactionCounts'] = <String, dynamic>{};
    return CommentModel.fromJson(map);
  }
}
