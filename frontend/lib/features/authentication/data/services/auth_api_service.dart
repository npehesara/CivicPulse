import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

class AuthApiService {
  final ApiClient apiClient;

  AuthApiService({required this.apiClient});

  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    final fields = request.toFormFields();
    final List<http.MultipartFile> files = [];

    if (request.profileImageBytes != null && request.profileImageBytes!.isNotEmpty) {
      files.add(http.MultipartFile.fromBytes(
        'profileImage',
        request.profileImageBytes!,
        filename: request.profileImageFilename ?? 'profile_image.jpg',
      ));
    } else if (request.profileImagePath != null && request.profileImagePath!.isNotEmpty) {
      files.add(await http.MultipartFile.fromPath(
        'profileImage',
        request.profileImagePath!,
        filename: request.profileImageFilename,
      ));
    }

    final response = await apiClient.postMultipart(
      ApiConstants.registerEndpoint,
      fields: fields,
      files: files,
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await apiClient.post(
      ApiConstants.loginEndpoint,
      body: request.toJson(),
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.get(
      ApiConstants.userMeEndpoint,
      requiresAuth: true,
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }
}
