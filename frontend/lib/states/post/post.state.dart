import 'package:flutter/foundation.dart';
import 'package:frontend/models/post/post.model.dart';

class PostState extends ChangeNotifier {
  static final instance = PostState._();
  PostState._();

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  bool _loading = false;
  bool get loading => _loading;

  void setPosts(List<PostModel> posts) {
    _posts = posts;
    notifyListeners();
  }

  void addPost(PostModel post) {
    _posts = [post, ..._posts];
    notifyListeners();
  }

  void updatePost(PostModel post) {
    _posts = _posts.map((p) => p.id == post.id ? post : p).toList();
    notifyListeners();
  }

  void removePost(String id) {
    _posts = _posts.where((p) => p.id != id).toList();
    notifyListeners();
  }

  void setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}
