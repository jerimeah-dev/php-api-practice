import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/repositories/post/post.repository.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';

class PostService {
  static final instance = PostService._();
  PostService._();

  final _repo      = PostRepository.instance;
  final _state     = PostState.instance;
  final _userState = UserState.instance;

  static const int _pageSize = 20;

  Future<void> loadFeed({String? authorId}) async {
    _state.clearPosts();
    _state.setLoading(true);
    await _fetchPage(offset: 0, authorId: authorId);
    _state.setLoading(false);
  }

  Future<void> loadNextPage({String? authorId}) async {
    if (_state.loading || !_state.hasMore) return;
    _state.setLoading(true);
    await _fetchPage(offset: _state.posts.length, authorId: authorId);
    _state.setLoading(false);
  }

  Future<void> _fetchPage({required int offset, String? authorId}) async {
    final res = await _repo.list(
      viewerId: _userState.id,
      limit:    _pageSize,
      offset:   offset,
      authorId: authorId,
    );
    if (res['status'] != 'success') return;
    final data  = res['data'] as Map<String, dynamic>;
    final total = (data['total'] as num).toInt();
    final more  = data['hasMore'] as bool;
    final posts = (data['posts'] as List? ?? [])
        .map((e) => _parsePost(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (offset == 0) {
      _state.setPosts(posts, total: total, hasMore: more);
    } else {
      _state.appendPosts(posts, total: total, hasMore: more);
    }
  }

  /// Raw page fetch for screens managing their own state (e.g. ProfileScreen)
  Future<Map<String, dynamic>> fetchPage({required int offset, required String? authorId}) =>
      _repo.list(
        viewerId: _userState.id,
        limit:    _pageSize,
        offset:   offset,
        authorId: authorId,
      );

  Future<PostModel?> create({required String content, List<String>? imageUrls}) async {
    final res  = await _repo.create(userId: _userState.id, content: content, imageUrls: imageUrls);
    final post = _parsePostRes(res);
    if (post != null) _state.addPost(post);
    return post;
  }

  Future<PostModel?> updateById({
    required String id,
    required String content,
    required List<String> imageUrls,
  }) async {
    final res  = await _repo.updateById(id: id, content: content, imageUrls: imageUrls);
    final post = _parsePostRes(res);
    if (post != null) _state.updatePost(post);
    return post;
  }

  Future<bool> deleteById(String id) async {
    final res = await _repo.deleteById(id);
    if (res['status'] == 'success') {
      _state.removePost(id);
      return true;
    }
    return false;
  }

  PostModel _parsePost(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final rc  = map['reactionCounts'];
    if (rc == null || rc is List) map['reactionCounts'] = <String, dynamic>{};
    return PostModel.fromJson(map);
  }

  PostModel? _parsePostRes(Map<String, dynamic> res) {
    if (res['status'] != 'success' || res['data']?['post'] == null) return null;
    return _parsePost(Map<String, dynamic>.from(res['data']['post']));
  }
}
