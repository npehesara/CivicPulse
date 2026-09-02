import '../../../../core/storage/session_manager.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService apiService;
  final SessionManager sessionManager;

  AuthRepositoryImpl({
    required this.apiService,
    required this.sessionManager,
  });

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    return await apiService.register(request);
  }

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await apiService.login(request);
    await sessionManager.saveSession(
      token: response.token,
      user: response.user,
    );
    return response;
  }

  @override
  Future<void> logout() async {
    await sessionManager.clearSession();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return await sessionManager.getUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await sessionManager.isLoggedIn();
  }
}
