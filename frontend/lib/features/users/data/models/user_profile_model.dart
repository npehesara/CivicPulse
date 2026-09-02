class UserProfileModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String role;
  final String accountStatus;
  final int? registeredTerritoryId;
  final String? registeredTerritoryName;
  final String? createdAt;
  final int reportedIssuesCount;
  final int upvotesGivenCount;

  const UserProfileModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    required this.role,
    required this.accountStatus,
    this.registeredTerritoryId,
    this.registeredTerritoryName,
    this.createdAt,
    this.reportedIssuesCount = 0,
    this.upvotesGivenCount = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}') ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      profileImage: json['profileImage']?.toString(),
      role: json['role']?.toString() ?? 'CITIZEN',
      accountStatus: json['accountStatus']?.toString() ?? 'ACTIVE',
      registeredTerritoryId: json['registeredTerritoryId'] is int
          ? json['registeredTerritoryId']
          : int.tryParse('${json['registeredTerritoryId']}'),
      registeredTerritoryName: json['registeredTerritoryName']?.toString(),
      createdAt: json['createdAt']?.toString(),
      reportedIssuesCount: json['reportedIssuesCount'] is int
          ? json['reportedIssuesCount']
          : int.tryParse('${json['reportedIssuesCount']}') ?? 0,
      upvotesGivenCount: json['upvotesGivenCount'] is int
          ? json['upvotesGivenCount']
          : int.tryParse('${json['upvotesGivenCount']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'role': role,
      'accountStatus': accountStatus,
      'registeredTerritoryId': registeredTerritoryId,
      'registeredTerritoryName': registeredTerritoryName,
      'createdAt': createdAt,
      'reportedIssuesCount': reportedIssuesCount,
      'upvotesGivenCount': upvotesGivenCount,
    };
  }
}
