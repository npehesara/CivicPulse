class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String role;
  final String accountStatus;
  final int? registeredTerritoryId;
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
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] is int ? json['userId'] as int : int.tryParse(json['userId'].toString()) ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String? ?? 'CITIZEN',
      accountStatus: json['accountStatus'] as String? ?? 'ACTIVE',
      registeredTerritoryId: json['registeredTerritoryId'] is int
          ? json['registeredTerritoryId'] as int
          : int.tryParse(json['registeredTerritoryId']?.toString() ?? ''),
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
      'registeredTerritoryId': registeredTerritoryId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isOfficial => role.toUpperCase() == 'OFFICIAL';
  bool get isCitizen => role.toUpperCase() == 'CITIZEN';
}
