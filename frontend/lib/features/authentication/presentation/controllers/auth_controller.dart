import 'package:flutter/foundation.dart';
import '../../../../core/auth/oauth_exception.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthController extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  Map<String, String>? _validationErrors;

  int? _selectedTerritoryId;
  String? _selectedProfileImagePath;
  List<int>? _selectedProfileImageBytes;
  String? _selectedProfileImageFilename;

  AuthController({required this.authRepository});

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  Map<String, String>? get validationErrors => _validationErrors;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  int? get selectedTerritoryId => _selectedTerritoryId;
  String? get selectedProfileImagePath => _selectedProfileImagePath;
  List<int>? get selectedProfileImageBytes => _selectedProfileImageBytes;
  String? get selectedProfileImageFilename => _selectedProfileImageFilename;

  void setSelectedTerritoryId(int? territoryId) {
    _selectedTerritoryId = territoryId;
    notifyListeners();
  }

  void setSelectedProfileImage({
    String? path,
    List<int>? bytes,
    String? filename,
  }) {
    _selectedProfileImagePath = path;
    _selectedProfileImageBytes = bytes;
    _selectedProfileImageFilename = filename;
    notifyListeners();
  }

  void clearRegistrationSelection() {
    _selectedTerritoryId = null;
    _selectedProfileImagePath = null;
    _selectedProfileImageBytes = null;
    _selectedProfileImageFilename = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await authRepository.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> loginWithOAuth() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();

    if (kDebugMode) {
      debugPrint('[AuthController] loginWithOAuth: initiating OAuth flow');
    }

    try {
      final user = await authRepository.loginWithOAuth();
      _currentUser = user;
      _status = AuthStatus.authenticated;
      if (kDebugMode) {
        debugPrint('[AuthController] loginWithOAuth: successfully authenticated user ${user.email} (userId: ${user.userId})');
      }
      notifyListeners();
      return true;
    } on OAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] loginWithOAuth OAuthException: ${e.message} (isUserCancelled: ${e.isUserCancelled})');
      }
      if (e.isUserCancelled) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] loginWithOAuth ApiException: ${e.message}');
      }
      _status = AuthStatus.error;
      _errorMessage = e.message;
      _validationErrors = e.validationErrors;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] loginWithOAuth unexpected error: $e');
      }
      _status = AuthStatus.error;
      _errorMessage = 'Unable to sign in with OAuth. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();

    try {
      final request = LoginRequestModel(email: email, password: password);
      final response = await authRepository.login(request);
      _currentUser = response.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      _validationErrors = e.validationErrors;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to sign in. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    int? registeredTerritoryId,
    String? profileImagePath,
    List<int>? profileImageBytes,
    String? profileImageFilename,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();

    try {
      final request = RegisterRequestModel(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        registeredTerritoryId: registeredTerritoryId ?? _selectedTerritoryId,
        profileImagePath: profileImagePath ?? _selectedProfileImagePath,
        profileImageBytes: profileImageBytes ?? _selectedProfileImageBytes,
        profileImageFilename: profileImageFilename ?? _selectedProfileImageFilename,
      );
      await authRepository.register(request);
      _status = AuthStatus.unauthenticated;
      clearRegistrationSelection();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      _validationErrors = e.validationErrors;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('[AuthController] logout: starting logout process');
    }
    _status = AuthStatus.loading;
    notifyListeners();

    await authRepository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    if (kDebugMode) {
      debugPrint('[AuthController] logout: completed logout, user is unauthenticated');
    }
    notifyListeners();
  }
}
