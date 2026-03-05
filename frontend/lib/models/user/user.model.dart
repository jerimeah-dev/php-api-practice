class UserModel {
  final String id;
  final String email;
  final String name;
  final DateTime? birthday;
  final String bio;
  final String websiteUrl;

  final int followersCount;
  final int followingCount;
  final int postsCount;

  final DateTime createdAt;

  final List<EducationModel> education;
  final List<WorkExperienceModel> workExperience;

  final List<ProfileImageModel> profileImages;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.birthday,
    required this.bio,
    required this.websiteUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.createdAt,
    this.education = const [],
    this.workExperience = const [],
    this.profileImages = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      birthday: json['birthday'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['birthday'] * 1000)
          : null,
      bio: json['bio'] ?? '',
      websiteUrl: json['websiteUrl'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] ?? 0) * 1000,
      ),
      education: json['education'] != null
          ? (json['education'] as List)
                .map(
                  (e) => EducationModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      workExperience: json['workExperience'] != null
          ? (json['workExperience'] as List)
                .map(
                  (e) => WorkExperienceModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : [],
      profileImages: json['profileImages'] != null
          ? (json['profileImages'] as List)
                .map(
                  (e) =>
                      ProfileImageModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'birthday': birthday != null
        ? (birthday!.millisecondsSinceEpoch ~/ 1000)
        : null,
    'bio': bio,
    'websiteUrl': websiteUrl,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'postsCount': postsCount,
    'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
    'education': education.map((e) => e.toJson()).toList(),
    'workExperience': workExperience.map((w) => w.toJson()).toList(),
    'profileImages': profileImages.map((p) => p.toJson()).toList(),
  };
}

class EducationModel {
  final String schoolName;
  final String degree;
  final String fieldOfStudy;
  final int startYear;
  final int? endYear;

  const EducationModel({
    required this.schoolName,
    required this.degree,
    required this.fieldOfStudy,
    required this.startYear,
    this.endYear,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      schoolName: json['schoolName'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'] ?? '',
      startYear: json['startYear'] ?? 0,
      endYear: json['endYear'],
    );
  }

  Map<String, dynamic> toJson() => {
    'schoolName': schoolName,
    'degree': degree,
    'fieldOfStudy': fieldOfStudy,
    'startYear': startYear,
    'endYear': endYear,
  };
}

class WorkExperienceModel {
  final String companyName;
  final String position;
  final int startYear;
  final int? endYear;

  const WorkExperienceModel({
    required this.companyName,
    required this.position,
    required this.startYear,
    this.endYear,
  });

  factory WorkExperienceModel.fromJson(Map<String, dynamic> json) {
    return WorkExperienceModel(
      companyName: json['companyName'] ?? '',
      position: json['position'] ?? '',
      startYear: json['startYear'] ?? 0,
      endYear: json['endYear'],
    );
  }

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'position': position,
    'startYear': startYear,
    'endYear': endYear,
  };
}

class ProfileImageModel {
  final String url;
  final String albumName;
  final DateTime uploadedAt;
  final bool isCurrent;

  const ProfileImageModel({
    required this.url,
    required this.albumName,
    required this.uploadedAt,
    this.isCurrent = false,
  });

  factory ProfileImageModel.fromJson(Map<String, dynamic> json) {
    return ProfileImageModel(
      url: json['url'] ?? '',
      albumName: json['albumName'] ?? '',
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(json['uploadedAt'] ?? 0),
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'albumName': albumName,
    'uploadedAt': uploadedAt.millisecondsSinceEpoch,
    'isCurrent': isCurrent,
  };
}
