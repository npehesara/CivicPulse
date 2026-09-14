import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/public_user_model.dart';
import '../models/user_profile_model.dart';

class UserApiService {
  final ApiClient apiClient;

  UserApiService({required this.apiClient});

  Future<UserProfileModel> getCurrentUserProfile() async {
    final response = await apiClient.get(ApiConstants.userMeEndpoint);
    return UserProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfileModel> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
    int? territoryId,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (profileImage != null) body['profileImage'] = profileImage;
    final effectiveTerritoryId = territoryId ?? registeredTerritoryId;
    if (effectiveTerritoryId != null) {
      body['registeredTerritoryId'] = effectiveTerritoryId;
      body['territoryId'] = effectiveTerritoryId;
    }
    if (homeLatitude != null) body['homeLatitude'] = homeLatitude;
    if (homeLongitude != null) body['homeLongitude'] = homeLongitude;

    final response = await apiClient.put(ApiConstants.userMeEndpoint, body: body);
    return UserProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfileModel> uploadProfileImage({
    List<int>? bytes,
    String? filePath,
    required String filename,
  }) async {
    final List<http.MultipartFile> files = [];

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

    if (bytes != null && bytes.isNotEmpty) {
      files.add(http.MultipartFile.fromBytes(
        'profileImage',
        bytes,
        filename: filename,
        contentType: mediaType,
      ));
    } else if (filePath != null && filePath.isNotEmpty) {
      files.add(await http.MultipartFile.fromPath(
        'profileImage',
        filePath,
        filename: filename,
        contentType: mediaType,
      ));
    } else {
      throw ArgumentError('Either bytes or filePath must be provided to upload profile image.');
    }

    final response = await apiClient.postMultipart(
      ApiConstants.userProfileImageEndpoint,
      files: files,
    );
    return UserProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfileModel> deleteProfileImage() async {
    final response = await apiClient.delete(ApiConstants.userProfileImageEndpoint);
    return UserProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    final body = <String, dynamic>{
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    if (confirmPassword != null) {
      body['confirmPassword'] = confirmPassword;
    }
    await apiClient.put(ApiConstants.userPasswordEndpoint, body: body);
  }

  Future<PublicUserModel> getPublicUserProfile(int userId) async {
    final response = await apiClient.get(ApiConstants.userProfileEndpoint(userId));
    return PublicUserModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<PublicUserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await apiClient.get(
      ApiConstants.userSearchEndpoint,
      queryParameters: {'query': query.trim()},
    );
    if (response is List) {
      return response.map((e) => PublicUserModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
