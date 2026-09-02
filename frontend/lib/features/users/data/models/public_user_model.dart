class PublicUserModel {
  final int userId;
  final String fullName;
  final String? profileImage;
  final String role;
  final int? registeredTerritoryId;
  final String? registeredTerritoryName;
  final String? createdAt;
  final int publicIssuesCount;

  const PublicUserModel({
    required this.userId,
    required this.fullName,
    this.profileImage,
    required this.role,
    this.registeredTerritoryId,
    this.registeredTerritoryName,
    this.createdAt,
    this.publicIssuesCount = 0,
  });

  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    return PublicUserModel(
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}') ?? 0,
      fullName: json['fullName']?.toString() ?? 'Citizen',
      profileImage: json['profileImage']?.toString(),
      role: json['role']?.toString() ?? 'CITIZEN',
      registeredTerritoryId: json['registeredTerritoryId'] is int
          ? json['registeredTerritoryId']
          : int.tryParse('${json['registeredTerritoryId']}'),
      registeredTerritoryName: json['registeredTerritoryName']?.toString(),
      createdAt: json['createdAt']?.toString(),
      publicIssuesCount: json['publicIssuesCount'] is int
          ? json['publicIssuesCount']
          : int.tryParse('${json['publicIssuesCount']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'profileImage': profileImage,
      'role': role,
      'registeredTerritoryId': registeredTerritoryId,
      'registeredTerritoryName': registeredTerritoryName,
      'createdAt': createdAt,
      'publicIssuesCount': publicIssuesCount,
    };
  }
}
