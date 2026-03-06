class CommentModel {
  final String id;
  final String postId;
  final String? parentId;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final Map<String, int> reactionCounts;
  final String? userReaction;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.parentId,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.imageUrls,
    required this.reactionCounts,
    required this.userReaction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] ?? '',
        postId: json['postId'] ?? '',
        parentId: json['parentId'] as String?,
        userId: json['userId'] ?? '',
        authorName: json['authorName'] ?? '',
        authorAvatarUrl: json['authorAvatarUrl'] ?? '',
        content: json['content'] ?? '',
        imageUrls: (json['imageUrls'] as List? ?? []).cast<String>(),
        reactionCounts: Map<String, dynamic>.from(json['reactionCounts'] ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        userReaction: json['userReaction'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            ((json['createdAt'] ?? 0) as int) * 1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            ((json['updatedAt'] ?? 0) as int) * 1000),
      );

  CommentModel copyWithReactions({
    required Map<String, int> reactionCounts,
    required String? userReaction,
  }) =>
      CommentModel(
        id: id,
        postId: postId,
        parentId: parentId,
        userId: userId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        content: content,
        imageUrls: imageUrls,
        reactionCounts: reactionCounts,
        userReaction: userReaction,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
