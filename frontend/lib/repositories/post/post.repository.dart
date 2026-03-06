import 'dart:convert';
import 'package:frontend/api/api.client.dart';

class PostRepository {
  static final instance = PostRepository._();
  PostRepository._();

  Future<Map<String, dynamic>> list({
    required String viewerId,
    required int limit,
    required int offset,
    String? authorId,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.list',
        'viewerId': viewerId,
        'limit': limit,
        'offset': offset,
        if (authorId != null) 'authorId': authorId,
      });

  Future<Map<String, dynamic>> getById({
    required String id,
    required String viewerId,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.getById',
        'id': id,
        'viewerId': viewerId,
      });

  Future<Map<String, dynamic>> create({
    required String userId,
    required String content,
    String? title,
    List<String>? imageUrls,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.create',
        'userId': userId,
        'content': content,
        if (title != null && title.isNotEmpty) 'title': title,
        if (imageUrls != null) 'imageUrls': jsonEncode(imageUrls),
      });

  Future<Map<String, dynamic>> updateById({
    required String id,
    required String content,
    required List<String> imageUrls,
    String? title,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'post.updateById',
        'id': id,
        'content': content,
        'imageUrls': jsonEncode(imageUrls),
        if (title != null) 'title': title,
      });

  Future<Map<String, dynamic>> deleteById(String id) =>
      ApiClient.instance.post('/api.php', {'method': 'post.deleteById', 'id': id});
}
