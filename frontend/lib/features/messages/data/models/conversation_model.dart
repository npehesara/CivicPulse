import '../../../users/data/models/public_user_model.dart';

class ConversationModel {
  final int conversationId;
  final String title;
  final String? createdAt;
  final String? updatedAt;
  final String? lastMessageText;
  final String? lastMessageAt;
  final int unreadCount;
  final PublicUserModel? otherParticipant;
  final List<PublicUserModel> participants;

  const ConversationModel({
    required this.conversationId,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherParticipant,
    this.participants = const [],
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    PublicUserModel? otherUser;
    if (json['otherParticipant'] is Map<String, dynamic>) {
      otherUser = PublicUserModel.fromJson(json['otherParticipant'] as Map<String, dynamic>);
    }

    final participantsList = <PublicUserModel>[];
    if (json['participants'] is List) {
      for (final p in json['participants'] as List) {
        if (p is Map<String, dynamic>) {
          participantsList.add(PublicUserModel.fromJson(p));
        }
      }
    }

    return ConversationModel(
      conversationId: json['conversationId'] is int ? json['conversationId'] : int.tryParse('${json['conversationId']}') ?? 0,
      title: json['title']?.toString() ?? otherUser?.fullName ?? 'Conversation',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      lastMessageText: json['lastMessageText']?.toString(),
      lastMessageAt: json['lastMessageAt']?.toString(),
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : int.tryParse('${json['unreadCount']}') ?? 0,
      otherParticipant: otherUser,
      participants: participantsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'title': title,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
      'otherParticipant': otherParticipant?.toJson(),
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}
