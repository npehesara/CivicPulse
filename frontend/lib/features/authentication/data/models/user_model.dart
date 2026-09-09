class UserModel {
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
  final DateTime? createdAt;

  const UserModel({
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedTerritoryId = json['territoryId'] is int
        ? json['territoryId'] as int
        : int.tryParse(json['territoryId']?.toString() ?? '');
    final parsedRegTerritoryId = json['registeredTerritoryId'] is int
        ? json['registeredTerritoryId'] as int
        : int.tryParse(json['registeredTerritoryId']?.toString() ?? '');

    return UserModel(
      userId: json['userId'] is int ? json['userId'] as int : int.tryParse(json['userId'].toString()) ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String? ?? 'CITIZEN',
      accountStatus: json['accountStatus'] as String? ?? 'ACTIVE',
      registeredTerritoryId: parsedRegTerritoryId ?? parsedTerritoryId,
      registeredTerritoryName: json['registeredTerritoryName'] as String? ?? json['territoryName'] as String?,
      territoryId: parsedTerritoryId ?? parsedRegTerritoryId,
      territoryName: json['territoryName'] as String? ?? json['registeredTerritoryName'] as String?,
      homeLatitude: json['homeLatitude'] != null ? double.tryParse(json['homeLatitude'].toString()) : null,
      homeLongitude: json['homeLongitude'] != null ? double.tryParse(json['homeLongitude'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
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
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isOfficial => role.toUpperCase() == 'OFFICIAL';
  bool get isCitizen => role.toUpperCase() == 'CITIZEN';
}
