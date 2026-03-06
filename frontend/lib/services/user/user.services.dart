import 'package:frontend/models/user/user.model.dart';
import 'package:frontend/repositories/user/user.repository.dart';
import 'package:frontend/states/user/user.state.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _repo  = UserRepository.instance;
  final _state = UserState.instance;

  Future<bool> login({required String email, required String password}) async {
    _state.setLoading(true);
    final res  = await _repo.login(email: email, password: password);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user != null;
  }

  Future<bool> register({required String email, required String password, String? name}) async {
    _state.setLoading(true);
    final res  = await _repo.register(email: email, password: password, name: name);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user != null;
  }

  void logout() => _state.clearUser();

  Future<void> refreshUser() async {
    if (_state.id.isEmpty) return;
    final res  = await _repo.getById(_state.id);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
  }

  Future<UserModel?> updateProfile({
    String? name,
    List<ProfileImageModel>? profileImages,
    List<ProfileImageModel>? coverImages,
  }) async {
    if (_state.id.isEmpty) return null;
    _state.setLoading(true);

    final res = await _repo.updateById(
      id: _state.id,
      name: name,
      profileImages: profileImages?.map((p) => p.toJson()).toList(),
      coverImages: coverImages?.map((p) => p.toJson()).toList(),
    );

    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user;
  }

  Future<UserModel?> setProfilePic(String imageUrl) async {
    if (_state.id.isEmpty) return null;
    final res = await _repo.setProfilePic(id: _state.id, imageUrl: imageUrl);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    return user;
  }

  final Map<String, UserModel> _cache = {};

  UserModel? getCached(String id) => _cache[id];

  Future<UserModel?> fetchAndCache(String id) async {
    final user = await fetchUser(id);
    if (user != null) _cache[id] = user;
    return user;
  }

  Future<UserModel?> fetchUser(String id) async {
    final res = await _repo.getById(id);
    return _parseUser(res);
  }

  UserModel? _parseUser(Map<String, dynamic> res) {
    if (res['status'] != 'success' || res['data']?['user'] == null) return null;
    final map = Map<String, dynamic>.from(res['data']['user']);
    map['profileImages'] = _decodeList(map['profileImages']);
    map['coverImages']   = _decodeList(map['coverImages']);
    return UserModel.fromJson(map);
  }

  List<Map<String, dynamic>> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }
}
