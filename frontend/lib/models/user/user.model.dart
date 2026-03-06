class UserModel {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final List<ProfileImageModel> profileImages;
  final List<ProfileImageModel> coverImages;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.profileImages,
    required this.coverImages,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        avatarUrl: json['avatarUrl'] ?? '',
        profileImages: (json['profileImages'] as List? ?? [])
            .map((e) => ProfileImageModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        coverImages: (json['coverImages'] as List? ?? [])
            .map((e) => ProfileImageModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            ((json['createdAt'] ?? 0) as int) * 1000),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'profileImages': profileImages.map((p) => p.toJson()).toList(),
        'coverImages': coverImages.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      };
}

class ProfileImageModel {
  final String url;
  final DateTime createdAt;

  const ProfileImageModel({required this.url, required this.createdAt});

  factory ProfileImageModel.fromJson(Map<String, dynamic> json) =>
      ProfileImageModel(
        url: json['url'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            ((json['createdAt'] ?? 0) as int) * 1000),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      };
}
