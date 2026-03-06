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
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.updateById',
        'id': id,
        if (name != null) 'name': name,
        if (profileImages != null) 'profileImages': jsonEncode(profileImages),
      });

  Future<Map<String, dynamic>> deleteById(String id) =>
      ApiClient.instance.post('/api.php', {'method': 'user.deleteById', 'id': id});
}
