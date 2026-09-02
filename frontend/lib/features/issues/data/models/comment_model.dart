class CommentModel {
  final int commentId;
  final int issueId;
  final int userId;
  final String userFullName;
  final String? userProfileImage;
  final String commentText;
  final String createdAt;
  final bool isOfficial;
  final bool isDeleted;

  const CommentModel({
    required this.commentId,
    required this.issueId,
    required this.userId,
    required this.userFullName,
    this.userProfileImage,
    required this.commentText,
    required this.createdAt,
    this.isOfficial = false,
    this.isDeleted = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] is int ? json['commentId'] : int.tryParse('${json['commentId']}') ?? 0,
      issueId: json['issueId'] is int ? json['issueId'] : int.tryParse('${json['issueId']}') ?? 0,
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}') ?? 0,
      userFullName: json['userFullName']?.toString() ?? 'Citizen',
      userProfileImage: json['userProfileImage']?.toString(),
      commentText: json['commentText']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      isOfficial: json['isOfficial'] == true,
      isDeleted: json['isDeleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'issueId': issueId,
      'userId': userId,
      'userFullName': userFullName,
      'userProfileImage': userProfileImage,
      'commentText': commentText,
      'createdAt': createdAt,
      'isOfficial': isOfficial,
      'isDeleted': isDeleted,
    };
  }
}
