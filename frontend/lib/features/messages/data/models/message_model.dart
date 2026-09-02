class MessageModel {
  final int messageId;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? senderProfileImage;
  final String content;
  final String sentAt;
  final bool isRead;
  final bool isMine;

  const MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderProfileImage,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.isMine = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] is int ? json['messageId'] : int.tryParse('${json['messageId']}') ?? 0,
      conversationId: json['conversationId'] is int ? json['conversationId'] : int.tryParse('${json['conversationId']}') ?? 0,
      senderId: json['senderId'] is int ? json['senderId'] : int.tryParse('${json['senderId']}') ?? 0,
      senderName: json['senderName']?.toString() ?? 'Citizen',
      senderProfileImage: json['senderProfileImage']?.toString(),
      content: json['content']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? '',
      isRead: json['isRead'] == true,
      isMine: json['isMine'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'content': content,
      'sentAt': sentAt,
      'isRead': isRead,
      'isMine': isMine,
    };
  }
}
