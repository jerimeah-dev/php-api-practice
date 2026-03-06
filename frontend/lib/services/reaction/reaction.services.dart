import 'package:frontend/repositories/reaction/reaction.repository.dart';
import 'package:frontend/states/comment/comment.state.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';

class ReactionService {
  static final instance = ReactionService._();
  ReactionService._();

  final _repo         = ReactionRepository.instance;
  final _postState    = PostState.instance;
  final _commentState = CommentState.instance;
  final _userState    = UserState.instance;

  Future<void> toggleReaction({
    required String targetType,
    required String targetId,
    required String type,
  }) async {
    // Optimistic update
    if (targetType == 'post') {
      _postState.applyOptimisticReaction(targetId, type);
    } else {
      _commentState.applyOptimisticReaction(targetId, type);
    }

    final res = await _repo.toggleReaction(
      userId:     _userState.id,
      targetType: targetType,
      targetId:   targetId,
      type:       type,
    );

    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>;
      final rcRaw = data['reactionCounts'];
      final rc = (rcRaw is Map)
          ? Map<String, int>.from(
              (rcRaw as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt())))
          : <String, int>{};
      final ur = data['userReaction'] as String?;
      if (targetType == 'post') {
        _postState.applyReactionResult(targetId, rc, ur);
      } else {
        _commentState.applyReactionResult(targetId, rc, ur);
      }
    } else {
      if (targetType == 'post') {
        _postState.rollbackReaction(targetId);
      } else {
        _commentState.rollbackReaction(targetId);
      }
    }
  }
}
