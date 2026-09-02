import 'package:civicpulse_frontend/features/messages/data/models/conversation_model.dart';
import 'package:civicpulse_frontend/features/messages/data/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message and Conversation Models Tests', () {
    test('MessageModel should parse from JSON and serialize correctly', () {
      final json = {
        'messageId': 10,
        'conversationId': 2,
        'senderId': 5,
        'senderName': 'John',
        'content': 'Hello, regarding the streetlight report...',
        'sentAt': '2026-09-02T03:00:00',
        'isRead': false,
        'isMine': true,
      };

      final msg = MessageModel.fromJson(json);

      expect(msg.messageId, 10);
      expect(msg.conversationId, 2);
      expect(msg.content, 'Hello, regarding the streetlight report...');
      expect(msg.isMine, true);
    });

    test('ConversationModel should parse from JSON and format participant titles', () {
      final json = {
        'conversationId': 2,
        'title': 'Officer John',
        'lastMessageText': 'Inspection scheduled',
        'lastMessageAt': '2026-09-02T03:10:00',
        'unreadCount': 2,
        'otherParticipant': {
          'userId': 5,
          'fullName': 'Officer John',
          'role': 'OFFICIAL',
        },
        'participants': [
          {
            'userId': 5,
            'fullName': 'Officer John',
            'role': 'OFFICIAL',
          }
        ],
      };

      final conv = ConversationModel.fromJson(json);

      expect(conv.conversationId, 2);
      expect(conv.title, 'Officer John');
      expect(conv.unreadCount, 2);
      expect(conv.otherParticipant?.fullName, 'Officer John');
    });
  });
}
