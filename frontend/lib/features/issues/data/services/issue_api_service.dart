import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/comment_model.dart';
import '../models/department_model.dart';
import '../models/issue_image_model.dart';
import '../models/issue_model.dart';
import '../models/status_model.dart';
import '../models/territory_model.dart';

class IssueApiService {
  final ApiClient apiClient;

  IssueApiService({required this.apiClient});

  Future<List<IssueModel>> getIssues({
    int? categoryId,
    int? statusId,
    int? territoryId,
    String? severity,
    String? visibility,
    int? departmentId,
    int? userId,
    String? keyword,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDir': sortDir,
    };

    if (categoryId != null) params['categoryId'] = categoryId;
    if (statusId != null) params['statusId'] = statusId;
    if (territoryId != null) params['territoryId'] = territoryId;
    if (severity != null && severity.isNotEmpty) params['severity'] = severity;
    if (visibility != null && visibility.isNotEmpty) params['visibility'] = visibility;
    if (departmentId != null) params['departmentId'] = departmentId;
    if (userId != null) params['userId'] = userId;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await apiClient.get(
      ApiConstants.issuesEndpoint,
      queryParameters: params,
    );

    if (response is Map<String, dynamic> && response.containsKey('content')) {
      final List content = response['content'] as List;
      return content.map((json) => IssueModel.fromJson(json as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return response.map((json) => IssueModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<IssueModel> getIssueById(int id) async {
    final response = await apiClient.get(ApiConstants.issueDetailEndpoint(id));
    final issue = IssueModel.fromJson(response as Map<String, dynamic>);
    
    // Fetch attached images & upvote status
    try {
      final images = await getIssueImages(id);
      final hasUpvoted = await getUpvoteStatus(id);
      return issue.copyWith(images: images, hasUpvoted: hasUpvoted);
    } catch (_) {
      return issue;
    }
  }

  Future<IssueModel> createIssue(Map<String, dynamic> body) async {
    final response = await apiClient.post(ApiConstants.issuesEndpoint, body: body);
    return IssueModel.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueModel> updateIssue(int id, Map<String, dynamic> body) async {
    final response = await apiClient.put(ApiConstants.issueDetailEndpoint(id), body: body);
    return IssueModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteIssue(int id) async {
    await apiClient.delete(ApiConstants.issueDetailEndpoint(id));
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get(ApiConstants.categoriesEndpoint);
    if (response is List) {
      return response.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<TerritoryModel>> getTerritories() async {
    final response = await apiClient.get(ApiConstants.territoriesEndpoint);
    if (response is List) {
      return response.map((e) => TerritoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<DepartmentModel>> getDepartments({int? territoryId}) async {
    final params = territoryId != null ? {'territoryId': territoryId} : null;
    final response = await apiClient.get(ApiConstants.departmentsEndpoint, queryParameters: params);
    if (response is List) {
      return response.map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<StatusModel>> getStatuses() async {
    final response = await apiClient.get(ApiConstants.statusesEndpoint);
    if (response is List) {
      return response.map((e) => StatusModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<CommentModel>> getComments(int issueId) async {
    final response = await apiClient.get(ApiConstants.issueCommentsEndpoint(issueId));
    if (response is List) {
      return response.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<CommentModel> addComment(int issueId, String text) async {
    final response = await apiClient.post(
      ApiConstants.issueCommentsEndpoint(issueId),
      body: {'commentText': text},
    );
    return CommentModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteComment(int commentId) async {
    await apiClient.delete(ApiConstants.deleteCommentEndpoint(commentId));
  }

  Future<void> addUpvote(int issueId) async {
    await apiClient.post(ApiConstants.issueUpvotesEndpoint(issueId));
  }

  Future<void> removeUpvote(int issueId) async {
    await apiClient.delete(ApiConstants.issueUpvotesEndpoint(issueId));
  }

  Future<bool> getUpvoteStatus(int issueId) async {
    try {
      final response = await apiClient.get(ApiConstants.issueUpvoteStatusEndpoint(issueId));
      if (response is Map<String, dynamic> && response.containsKey('hasUpvoted')) {
        return response['hasUpvoted'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<IssueImageModel>> getIssueImages(int issueId) async {
    final response = await apiClient.get(ApiConstants.issueImagesEndpoint(issueId));
    if (response is List) {
      return response.map((e) => IssueImageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<IssueImageModel> addImageToIssue(int issueId, String imageUrl, {String? filename}) async {
    final response = await apiClient.post(
      ApiConstants.issueImagesEndpoint(issueId),
      body: {
        'imageUrl': imageUrl,
        if (filename != null) 'originalFilename': filename,
      },
    );
    return IssueImageModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteIssueImage(int issueId, int imageId) async {
    await apiClient.delete(ApiConstants.deleteIssueImageEndpoint(issueId, imageId));
  }
}
