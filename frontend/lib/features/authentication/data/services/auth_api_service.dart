import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
      final filename = request.profileImageFilename ?? 'profile_image.jpg';
      final dotIndex = filename.lastIndexOf('.');
      final ext = (dotIndex != -1 && dotIndex < filename.length - 1)
          ? filename.substring(dotIndex + 1).toLowerCase()
          : 'jpg';

      final MediaType mediaType;
      if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      files.add(http.MultipartFile.fromBytes(
        'profileImage',
        request.profileImageBytes!,
        filename: filename,
        contentType: mediaType,
      ));
    } else if (request.profileImagePath != null && request.profileImagePath!.isNotEmpty) {
      final filename = request.profileImageFilename ?? 'profile_image.jpg';
      final dotIndex = filename.lastIndexOf('.');
      final ext = (dotIndex != -1 && dotIndex < filename.length - 1)
          ? filename.substring(dotIndex + 1).toLowerCase()
          : 'jpg';

      final MediaType mediaType;
      if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      files.add(await http.MultipartFile.fromPath(
        'profileImage',
        request.profileImagePath!,
        filename: filename,
        contentType: mediaType,
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
