import 'package:flutter/foundation.dart';
import 'package:frontend/models/user/user.model.dart';

class UserState extends ChangeNotifier {
  UserState._();
  static final instance = UserState._();

  UserModel? _user;
  UserModel? get user => _user;

  String _id = '';
  String get id => _id;

  String _email = '';
  String get email => _email;

  String _name = '';
  String get name => _name;

  String _avatarUrl = '';
  String get avatarUrl => _avatarUrl;

  List<ProfileImageModel> _profileImages = [];
  List<ProfileImageModel> get profileImages => _profileImages;

  List<ProfileImageModel> _coverImages = [];
  List<ProfileImageModel> get coverImages => _coverImages;

  DateTime _createdAt = DateTime.now();
  DateTime get createdAt => _createdAt;

  bool _loading = false;
  bool get loading => _loading;

  void setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void setUser(UserModel? u) {
    _user = u;
    if (u == null) {
      _clearFields();
    } else {
      _id            = u.id;
      _email         = u.email;
      _name          = u.name;
      _avatarUrl     = u.avatarUrl;
      _profileImages = u.profileImages;
      _coverImages   = u.coverImages;
      _createdAt     = u.createdAt;
    }
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _clearFields();
    notifyListeners();
  }

  void _clearFields() {
    _id            = '';
    _email         = '';
    _name          = '';
    _avatarUrl     = '';
    _profileImages = [];
    _coverImages   = [];
    _createdAt     = DateTime.now();
  }
}
