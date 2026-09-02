import 'user_model.dart';

class AuthResponseModel {
  final String token;
  final String message;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.message,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String? ?? '',
      message: json['message'] as String? ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel(
              userId: 0,
              fullName: '',
              email: '',
              role: 'CITIZEN',
              accountStatus: 'ACTIVE',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'message': message,
      'user': user.toJson(),
    };
  }
}
