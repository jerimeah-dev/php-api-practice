import 'dart:convert';
import 'package:frontend/models/user/user.model.dart';
import 'package:frontend/repositories/user/user.repository.dart';
import 'package:frontend/states/user/user.state.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _repo = UserRepository.instance;
  final _state = UserState.instance;

  // ---------------- Actions ----------------

  Future<bool> login({required String email, required String password}) async {
    _state.setLoading(true);
    final res = await _repo.login(email: email, password: password);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user != null;
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _state.setLoading(true);
    final res = await _repo.register(email: email, password: password, name: name);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user != null;
  }

  void logout() => _state.clearUser();

  Future<void> refreshUser() async {
    if (_state.id.isEmpty) return;
    final res = await _repo.getById(_state.id);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
  }

  Future<UserModel?> updateProfile({
    String? email,
    String? password,
    String? name,
    int? birthday,
    String? bio,
    String? websiteUrl,
    List<ProfileImageModel>? profileImages,
  }) async {
    if (_state.id.isEmpty) return null;
    _state.setLoading(true);

    final res = await _repo.updateById(
      id: _state.id,
      email: email,
      password: password,
      name: name,
      birthday: birthday,
      bio: bio,
      websiteUrl: websiteUrl,
      profileImages: profileImages?.map((p) => p.toJson()).toList(),
    );

    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user;
  }

  // ---------------- Helpers ----------------

  UserModel? _parseUser(Map<String, dynamic> res) {
    if (res['status'] != 'success' || res['data']?['user'] == null) return null;

    final map = Map<String, dynamic>.from(res['data']['user']);
    map['education'] = _decodeList(map['education']);
    map['workExperience'] = _decodeList(map['workExperience']);
    map['profileImages'] = _decodeList(map['profileImages']);

    return UserModel.fromJson(map);
  }

  List<Map<String, dynamic>> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } else if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}
