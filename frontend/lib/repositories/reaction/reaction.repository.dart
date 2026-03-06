import 'package:frontend/api/api.client.dart';

class ReactionRepository {
  static final instance = ReactionRepository._();
  ReactionRepository._();

  Future<Map<String, dynamic>> toggleReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String type,
  }) =>
      ApiClient.instance.post('/api.php', {
        'method': 'reaction.toggle',
        'userId': userId,
        'targetType': targetType,
        'targetId': targetId,
        'type': type,
      });
}
