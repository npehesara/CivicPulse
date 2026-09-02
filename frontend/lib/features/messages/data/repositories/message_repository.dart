import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_api_service.dart';

abstract class MessageRepository {
  Future<List<ConversationModel>> getUserConversations();
  Future<ConversationModel> createOrGetConversation(int recipientUserId, {String? initialMessage});
  Future<List<MessageModel>> getConversationMessages(int conversationId);
  Future<MessageModel> sendMessage(int conversationId, String content);
  Future<void> markConversationAsRead(int conversationId);
}

class MessageRepositoryImpl implements MessageRepository {
  final MessageApiService apiService;

  MessageRepositoryImpl({required this.apiService});

  @override
  Future<List<ConversationModel>> getUserConversations() => apiService.getUserConversations();

  @override
  Future<ConversationModel> createOrGetConversation(int recipientUserId, {String? initialMessage}) =>
      apiService.createOrGetConversation(recipientUserId, initialMessage: initialMessage);

  @override
  Future<List<MessageModel>> getConversationMessages(int conversationId) =>
      apiService.getConversationMessages(conversationId);

  @override
  Future<MessageModel> sendMessage(int conversationId, String content) =>
      apiService.sendMessage(conversationId, content);

  @override
  Future<void> markConversationAsRead(int conversationId) =>
      apiService.markConversationAsRead(conversationId);
}
