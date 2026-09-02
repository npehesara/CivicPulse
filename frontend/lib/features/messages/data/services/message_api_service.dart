import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessageApiService {
  final ApiClient apiClient;

  MessageApiService({required this.apiClient});

  Future<List<ConversationModel>> getUserConversations() async {
    final response = await apiClient.get(ApiConstants.conversationsEndpoint);
    if (response is List) {
      return response.map((c) => ConversationModel.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ConversationModel> createOrGetConversation(int recipientUserId, {String? initialMessage}) async {
    final body = <String, dynamic>{
      'recipientUserId': recipientUserId,
      if (initialMessage != null && initialMessage.isNotEmpty) 'initialMessage': initialMessage,
    };
    final response = await apiClient.post(ApiConstants.conversationsEndpoint, body: body);
    return ConversationModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getConversationMessages(int conversationId) async {
    final response = await apiClient.get(ApiConstants.conversationMessagesEndpoint(conversationId));
    if (response is List) {
      return response.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<MessageModel> sendMessage(int conversationId, String content) async {
    final response = await apiClient.post(
      ApiConstants.conversationMessagesEndpoint(conversationId),
      body: {'content': content},
    );
    return MessageModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> markConversationAsRead(int conversationId) async {
    await apiClient.put(ApiConstants.markConversationReadEndpoint(conversationId));
  }
}
