import 'dart:convert';
import 'package:frontend/api/api.client.dart';

class UserRepository {
  static final instance = UserRepository._();
  UserRepository._();

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.register',
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.login',
        'email': email,
        'password': password,
      });

  Future<Map<String, dynamic>> getById(String id) =>
      ApiClient.instance.post('/api.php', {'method': 'user.findById', 'id': id});

  Future<Map<String, dynamic>> updateById({
    required String id,
    String? name,
    List<Map<String, dynamic>>? profileImages,
    List<Map<String, dynamic>>? coverImages,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.updateById',
        'id': id,
        if (name != null) 'name': name,
        if (profileImages != null) 'profileImages': jsonEncode(profileImages),
        if (coverImages != null) 'coverImages': jsonEncode(coverImages),
      });

  Future<Map<String, dynamic>> deleteById(String id) =>
      ApiClient.instance.post('/api.php', {'method': 'user.deleteById', 'id': id});

  Future<Map<String, dynamic>> setProfilePic({
    required String id,
    required String imageUrl,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.setProfilePic',
        'id': id,
        'imageUrl': imageUrl,
      });
}
