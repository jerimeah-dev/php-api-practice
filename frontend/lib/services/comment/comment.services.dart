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

  Future<void> loadForPost(String postId) async {
    _state.clearComments();
    _state.setLoading(true);
    final res = await _repo.list(
      postId:   postId,
      viewerId: _userState.id,
      limit:    200,
      offset:   0,
    );
    if (res['status'] == 'success') {
      final data     = res['data'] as Map<String, dynamic>;
      final hasMore  = data['hasMore'] as bool;
      final comments = (data['comments'] as List? ?? [])
          .map((e) => _parseComment(Map<String, dynamic>.from(e as Map)))
          .toList();
      _state.setComments(comments, hasMore: hasMore);
    }
    _state.setLoading(false);
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
