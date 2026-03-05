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
      ApiClient.instance.post('/api.php', {
        'method': 'user.findById',
        'id': id,
      });

  Future<Map<String, dynamic>> getByEmail(String email) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.findByEmail',
        'email': email,
      });

  Future<Map<String, dynamic>> updateById({
    required String id,
    String? email,
    String? password,
    String? name,
    int? birthday,
    String? bio,
    String? websiteUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? workExperience,
    List<Map<String, dynamic>>? profileImages,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.updateById',
        'id': id,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (name != null) 'name': name,
        if (birthday != null) 'birthday': birthday,
        if (bio != null) 'bio': bio,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        if (followersCount != null) 'followersCount': followersCount,
        if (followingCount != null) 'followingCount': followingCount,
        if (postsCount != null) 'postsCount': postsCount,
        if (education != null) 'education': jsonEncode(education),
        if (workExperience != null) 'workExperience': jsonEncode(workExperience),
        if (profileImages != null) 'profileImages': jsonEncode(profileImages),
      });

  Future<Map<String, dynamic>> deleteById(String id) =>
      ApiClient.instance.post('/api.php', {
        'method': 'user.deleteById',
        'id': id,
      });

  Future<Map<String, dynamic>> listAll() =>
      ApiClient.instance.post('/api.php', {'method': 'user.listAll'});
}
