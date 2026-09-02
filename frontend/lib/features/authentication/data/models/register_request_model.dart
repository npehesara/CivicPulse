class RegisterRequestModel {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;

  RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      map['phoneNumber'] = phoneNumber!.trim();
    }
    return map;
  }
}
