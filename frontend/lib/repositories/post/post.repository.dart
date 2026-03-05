import 'dart:convert';
import 'package:frontend/api/api.client.dart';

class PostRepository {
  static final instance = PostRepository._();
  PostRepository._();

  Future<Map<String, dynamic>> create({
    required String userId,
    required String title,
    required String content,
    List<String>? imageUrls,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.create',
        'userId': userId,
        'title': title,
        'content': content,
        if (imageUrls != null) 'imageUrls': jsonEncode(imageUrls),
      });

  Future<Map<String, dynamic>> getById({
    required String id,
    required String userId,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.getById',
        'id': id,
        'userId': userId,
      });

  Future<Map<String, dynamic>> updateById({
    required String id,
    required String userId,
    required String title,
    required String content,
    required List<String> imageUrls,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.updateById',
        'id': id,
        'userId': userId,
        'title': title,
        'content': content,
        'imageUrls': jsonEncode(imageUrls),
      });

  Future<Map<String, dynamic>> deleteById({
    required String id,
    required String userId,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.deleteById',
        'id': id,
        'userId': userId,
      });

  Future<Map<String, dynamic>> listAll({required String userId}) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.listAll',
        'userId': userId,
      });

  Future<Map<String, dynamic>> listByUser(String userId) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.listByUser',
        'userId': userId,
      });

  Future<Map<String, dynamic>> toggleReaction({
    required String postId,
    required String userId,
    required String type,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'reaction.toggle',
        'postId': postId,
        'userId': userId,
        'type': type,
      });
}
