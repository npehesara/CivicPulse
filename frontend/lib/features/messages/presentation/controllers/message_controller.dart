import 'package:flutter/material.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository.dart';

class MessageController extends ChangeNotifier {
  final MessageRepository messageRepository;

  MessageController({required this.messageRepository});

  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  int get totalUnreadCount {
    return _conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await messageRepository.getUserConversations();
      _conversations = list;
    } catch (e) {
      _errorMessage = 'Could not load messages.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int conversationId) async {
    _isLoadingMessages = true;
    notifyListeners();

    try {
      final msgs = await messageRepository.getConversationMessages(conversationId);
      _currentMessages = msgs;

      // Update local unread count
      final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (idx != -1) {
        final updatedConv = ConversationModel(
          conversationId: _conversations[idx].conversationId,
          title: _conversations[idx].title,
          createdAt: _conversations[idx].createdAt,
          updatedAt: _conversations[idx].updatedAt,
          lastMessageText: _conversations[idx].lastMessageText,
          lastMessageAt: _conversations[idx].lastMessageAt,
          unreadCount: 0,
          otherParticipant: _conversations[idx].otherParticipant,
          participants: _conversations[idx].participants,
        );
        _conversations[idx] = updatedConv;
      }
    } catch (_) {
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(int conversationId, String content) async {
    if (content.trim().isEmpty) return false;
    _isSending = true;
    notifyListeners();

    try {
      final newMsg = await messageRepository.sendMessage(conversationId, content.trim());
      _currentMessages = [..._currentMessages, newMsg];
      
      // Update last message in conversation list
      final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (idx != -1) {
        final updatedConv = ConversationModel(
          conversationId: _conversations[idx].conversationId,
          title: _conversations[idx].title,
          createdAt: _conversations[idx].createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          lastMessageText: content.trim(),
          lastMessageAt: DateTime.now().toIso8601String(),
          unreadCount: _conversations[idx].unreadCount,
          otherParticipant: _conversations[idx].otherParticipant,
          participants: _conversations[idx].participants,
        );
        _conversations[idx] = updatedConv;
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSending = false;
      notifyListeners();
      return false;
    }
  }
}
