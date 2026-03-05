import 'package:flutter/foundation.dart';
import 'package:frontend/models/user/user.model.dart';

class UserState extends ChangeNotifier {
  UserState._();
  static final instance = UserState._();

  // ---------------- Core Object ----------------
  UserModel? _user;
  UserModel? get user => _user;

  // ---------------- User fields ----------------
  String _id = '';
  String get id => _id;

  String _email = '';
  String get email => _email;

  String _name = '';
  String get name => _name;

  DateTime? _birthday;
  DateTime? get birthday => _birthday;

  String _bio = '';
  String get bio => _bio;

  String _websiteUrl = '';
  String get websiteUrl => _websiteUrl;

  int _followersCount = 0;
  int get followersCount => _followersCount;

  int _followingCount = 0;
  int get followingCount => _followingCount;

  int _postsCount = 0;
  int get postsCount => _postsCount;

  DateTime _createdAt = DateTime.now();
  DateTime get createdAt => _createdAt;

  List<EducationModel> _education = [];
  List<EducationModel> get education => _education;

  List<WorkExperienceModel> _workExperience = [];
  List<WorkExperienceModel> get workExperience => _workExperience;

  List<ProfileImageModel> _profileImages = [];
  List<ProfileImageModel> get profileImages => _profileImages;

  bool _loading = false;
  bool get loading => _loading;

  // ---------------- Setters ----------------

  void setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  /// Set the entire user object
  void setUser(UserModel? u) {
    _user = u;

    if (u == null) {
      clearUser();
      return;
    }

    _id = u.id;
    _email = u.email;
    _name = u.name;
    _birthday = u.birthday;
    _bio = u.bio;
    _websiteUrl = u.websiteUrl;
    _followersCount = u.followersCount;
    _followingCount = u.followingCount;
    _postsCount = u.postsCount;
    _createdAt = u.createdAt;
    _education = u.education;
    _workExperience = u.workExperience;
    _profileImages = u.profileImages;

    notifyListeners();
  }

  /// Clear user
  void clearUser() {
    _user = null;

    _id = '';
    _email = '';
    _name = '';
    _birthday = null;
    _bio = '';
    _websiteUrl = '';
    _followersCount = 0;
    _followingCount = 0;
    _postsCount = 0;
    _createdAt = DateTime.now();
    _education = [];
    _workExperience = [];
    _profileImages = [];

    notifyListeners();
  }

  void incrementPostsCount() {
    _postsCount++;
    notifyListeners();
  }

  void decrementPostsCount() {
    if (_postsCount > 0) _postsCount--;
    notifyListeners();
  }

  /// Update single field (Selector optimized)
  void updateField<T>(T value, void Function(UserState state, T val) updater) {
    updater(this, value);
    notifyListeners();
  }
}
