class RegisterRequestModel {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final int? registeredTerritoryId;
  final String? profileImagePath;
  final List<int>? profileImageBytes;
  final String? profileImageFilename;

  RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.registeredTerritoryId,
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
    if (registeredTerritoryId != null) {
      fields['registeredTerritoryId'] = registeredTerritoryId.toString();
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
    if (registeredTerritoryId != null) {
      map['registeredTerritoryId'] = registeredTerritoryId;
    }
    if (profileImagePath != null) {
      map['profileImagePath'] = profileImagePath;
    }
    return map;
  }
}
