import '../../../core/network/api_client.dart';
import '../domain/chat_models.dart';

class ChatRepository {
  const ChatRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ChatMessage>> fetchTaskMessages(String taskId) async {
    final data =
        await _apiClient.get('/chats', queryParameters: {'taskId': taskId})
            as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> sendTaskMessage({
    required String taskId,
    required String receiverId,
    required String body,
  }) async {
    final data =
        await _apiClient.post(
              '/chats',
              data: {'taskId': taskId, 'receiverId': receiverId, 'body': body},
            )
            as Map<String, dynamic>;
    return ChatMessage.fromJson(data);
  }
}
