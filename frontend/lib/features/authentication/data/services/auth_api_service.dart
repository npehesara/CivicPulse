import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

class AuthApiService {
  final ApiClient apiClient;

  AuthApiService({required this.apiClient});

  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    final response = await apiClient.post(
      ApiConstants.registerEndpoint,
      body: request.toJson(),
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
}
