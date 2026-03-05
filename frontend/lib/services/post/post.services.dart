import 'dart:convert';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/repositories/post/post.repository.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';

class PostService {
  static final instance = PostService._();
  PostService._();

  final _repo = PostRepository.instance;
  final _state = PostState.instance;
  final _userState = UserState.instance;

  Future<void> loadAll() async {
    _state.setLoading(true);
    final res = await _repo.listAll();
    if (res['status'] == 'success') {
      final list = (res['data']['posts'] as List? ?? [])
          .map((e) => _parsePost({'status': 'success', 'data': {'post': e}}))
          .whereType<PostModel>()
          .toList();
      _state.setPosts(list);
    }
    _state.setLoading(false);
  }

  Future<PostModel?> create({
    required String title,
    required String content,
    List<String>? imageUrls,
  }) async {
    final userId = _userState.id;
    if (userId.isEmpty) return null;

    final res = await _repo.create(
      userId: userId,
      title: title,
      content: content,
      imageUrls: imageUrls,
    );
    final post = _parsePost(res);
    if (post != null) _state.addPost(post);
    return post;
  }

  Future<PostModel?> updateById({
    required String id,
    required String title,
    required String content,
    required List<String> imageUrls,
  }) async {
    final res = await _repo.updateById(
      id: id,
      userId: _userState.id,
      title: title,
      content: content,
      imageUrls: imageUrls,
    );
    final post = _parsePost(res);
    if (post != null) _state.updatePost(post);
    return post;
  }

  Future<bool> deleteById(String id) async {
    final res = await _repo.deleteById(id: id, userId: _userState.id);
    if (res['status'] == 'success') {
      _state.removePost(id);
      return true;
    }
    return false;
  }

  PostModel? _parsePost(Map<String, dynamic> res) {
    if (res['status'] != 'success' || res['data']?['post'] == null) return null;
    final map = Map<String, dynamic>.from(res['data']['post']);
    map['imageUrls'] = _decodeStringList(map['imageUrls']);
    return PostModel.fromJson(map);
  }

  List<String> _decodeStringList(dynamic value) {
    if (value == null) return [];
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } else if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
