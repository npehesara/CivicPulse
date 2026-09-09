class RegisterRequestModel {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final int? registeredTerritoryId;
  final int? territoryId;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? profileImagePath;
  final List<int>? profileImageBytes;
  final String? profileImageFilename;

  RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.registeredTerritoryId,
    this.territoryId,
    this.homeLatitude,
    this.homeLongitude,
    this.profileImagePath,
    this.profileImageBytes,
    this.profileImageFilename,
  });

  Map<String, String> toFormFields() {
    final fields = <String, String>{
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      fields['phoneNumber'] = phoneNumber!.trim();
    }
    final effectiveTerritoryId = territoryId ?? registeredTerritoryId;
    if (effectiveTerritoryId != null) {
      fields['territoryId'] = effectiveTerritoryId.toString();
      fields['registeredTerritoryId'] = effectiveTerritoryId.toString();
    }
    if (homeLatitude != null) {
      fields['homeLatitude'] = homeLatitude.toString();
    }
    if (homeLongitude != null) {
      fields['homeLongitude'] = homeLongitude.toString();
    }
    return fields;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      map['phoneNumber'] = phoneNumber!.trim();
    }
    final effectiveTerritoryId = territoryId ?? registeredTerritoryId;
    if (effectiveTerritoryId != null) {
      map['territoryId'] = effectiveTerritoryId;
      map['registeredTerritoryId'] = effectiveTerritoryId;
    }
    if (homeLatitude != null) {
      map['homeLatitude'] = homeLatitude;
    }
    if (homeLongitude != null) {
      map['homeLongitude'] = homeLongitude;
    }
    if (profileImagePath != null) {
      map['profileImagePath'] = profileImagePath;
    }
    return map;
  }
}
