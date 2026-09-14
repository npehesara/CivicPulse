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
  final int? territoryId;
  final String? territoryName;
  final double? homeLatitude;
  final double? homeLongitude;
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
    this.territoryId,
    this.territoryName,
    this.homeLatitude,
    this.homeLongitude,
    this.createdAt,
    this.reportedIssuesCount = 0,
    this.upvotesGivenCount = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final parsedTerritoryId = json['territoryId'] is int
        ? json['territoryId'] as int
        : int.tryParse(json['territoryId']?.toString() ?? '');
    final parsedRegTerritoryId = json['registeredTerritoryId'] is int
        ? json['registeredTerritoryId'] as int
        : int.tryParse(json['registeredTerritoryId']?.toString() ?? '');

    return UserProfileModel(
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}') ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      profileImage: json['profileImage']?.toString(),
      role: json['role']?.toString() ?? 'CITIZEN',
      accountStatus: json['accountStatus']?.toString() ?? 'ACTIVE',
      registeredTerritoryId: parsedRegTerritoryId ?? parsedTerritoryId,
      registeredTerritoryName: json['registeredTerritoryName']?.toString() ?? json['territoryName']?.toString(),
      territoryId: parsedTerritoryId ?? parsedRegTerritoryId,
      territoryName: json['territoryName']?.toString() ?? json['registeredTerritoryName']?.toString(),
      homeLatitude: json['homeLatitude'] != null ? double.tryParse(json['homeLatitude'].toString()) : null,
      homeLongitude: json['homeLongitude'] != null ? double.tryParse(json['homeLongitude'].toString()) : null,
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
      'registeredTerritoryId': registeredTerritoryId ?? territoryId,
      'registeredTerritoryName': registeredTerritoryName ?? territoryName,
      'territoryId': territoryId ?? registeredTerritoryId,
      'territoryName': territoryName ?? registeredTerritoryName,
      'homeLatitude': homeLatitude,
      'homeLongitude': homeLongitude,
      'createdAt': createdAt,
      'reportedIssuesCount': reportedIssuesCount,
      'upvotesGivenCount': upvotesGivenCount,
    };
  }

  UserProfileModel copyWith({
    int? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? role,
    String? accountStatus,
    int? registeredTerritoryId,
    String? registeredTerritoryName,
    int? territoryId,
    String? territoryName,
    double? homeLatitude,
    double? homeLongitude,
    String? createdAt,
    int? reportedIssuesCount,
    int? upvotesGivenCount,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      registeredTerritoryId: registeredTerritoryId ?? this.registeredTerritoryId,
      registeredTerritoryName: registeredTerritoryName ?? this.registeredTerritoryName,
      territoryId: territoryId ?? this.territoryId,
      territoryName: territoryName ?? this.territoryName,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      createdAt: createdAt ?? this.createdAt,
      reportedIssuesCount: reportedIssuesCount ?? this.reportedIssuesCount,
      upvotesGivenCount: upvotesGivenCount ?? this.upvotesGivenCount,
    );
  }
}
