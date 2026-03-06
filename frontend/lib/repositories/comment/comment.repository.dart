import 'dart:convert';
import 'package:frontend/api/api.client.dart';

class CommentRepository {
  static final instance = CommentRepository._();
  CommentRepository._();

  Future<Map<String, dynamic>> list({
    required String postId,
    required String viewerId,
    required int limit,
    required int offset,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'comment.list',
        'postId': postId,
        'viewerId': viewerId,
        'limit': limit,
        'offset': offset,
      });

  Future<Map<String, dynamic>> create({
    required String userId,
    required String postId,
    required String content,
    String? parentId,
    List<String>? imageUrls,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'comment.create',
        'userId': userId,
        'postId': postId,
        'content': content,
        if (parentId != null) 'parentId': parentId,
        if (imageUrls != null) 'imageUrls': jsonEncode(imageUrls),
      });

  Future<Map<String, dynamic>> updateById({
    required String id,
    required String content,
    required List<String> imageUrls,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'comment.updateById',
        'id': id,
        'content': content,
        'imageUrls': jsonEncode(imageUrls),
      });

  Future<Map<String, dynamic>> deleteById(String id) =>
      ApiClient.instance.post('/api.php', {'method': 'comment.deleteById', 'id': id});
}
