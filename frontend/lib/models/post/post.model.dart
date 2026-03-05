class PostModel {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        authorName: json['authorName'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        imageUrls: (json['imageUrls'] as List? ?? []).map((e) => e.toString()).toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((json['createdAt'] ?? 0) as int) * 1000,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          ((json['updatedAt'] ?? 0) as int) * 1000,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'authorName': authorName,
        'title': title,
        'content': content,
        'imageUrls': imageUrls,
        'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
        'updatedAt': updatedAt.millisecondsSinceEpoch ~/ 1000,
      };
}
