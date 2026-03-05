class PostModel {
  final String id;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String title;
  final String content;
  final List<String> imageUrls;
  final Map<String, int> reactionCounts;
  final String? userReaction;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.reactionCounts,
    required this.userReaction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        authorName: json['authorName'] ?? '',
        authorAvatarUrl: json['authorAvatarUrl'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        imageUrls: (json['imageUrls'] as List? ?? []).map((e) => e.toString()).toList(),
        reactionCounts: (json['reactionCounts'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
        userReaction: json['userReaction'] as String?,
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
        'authorAvatarUrl': authorAvatarUrl,
        'title': title,
        'content': content,
        'imageUrls': imageUrls,
        'reactionCounts': reactionCounts,
        'userReaction': userReaction,
        'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
        'updatedAt': updatedAt.millisecondsSinceEpoch ~/ 1000,
      };

  PostModel copyWithReactions({
    required Map<String, int> reactionCounts,
    required String? userReaction,
  }) =>
      PostModel(
        id: id,
        userId: userId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        title: title,
        content: content,
        imageUrls: imageUrls,
        reactionCounts: reactionCounts,
        userReaction: userReaction,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
