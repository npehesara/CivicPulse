import '../models/category_model.dart';
import '../models/comment_model.dart';
import '../models/department_model.dart';
import '../models/issue_image_model.dart';
import '../models/issue_model.dart';
import '../models/status_model.dart';
import '../models/territory_model.dart';
import '../services/issue_api_service.dart';

abstract class IssueRepository {
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
  });

  Future<IssueModel> getIssueById(int id);
  Future<IssueModel> createIssue(Map<String, dynamic> body);
  Future<IssueModel> updateIssue(int id, Map<String, dynamic> body);
  Future<void> deleteIssue(int id);
  Future<List<CategoryModel>> getCategories();
  Future<List<TerritoryModel>> getTerritories();
  Future<List<DepartmentModel>> getDepartments({int? territoryId});
  Future<List<StatusModel>> getStatuses();
  Future<List<CommentModel>> getComments(int issueId);
  Future<CommentModel> addComment(int issueId, String text);
  Future<void> deleteComment(int commentId);
  Future<void> addUpvote(int issueId);
  Future<void> removeUpvote(int issueId);
  Future<bool> getUpvoteStatus(int issueId);
  Future<List<IssueImageModel>> getIssueImages(int issueId);
  Future<IssueImageModel> addImageToIssue(int issueId, String imageUrl, {String? filename});
  Future<void> deleteIssueImage(int issueId, int imageId);
}

class IssueRepositoryImpl implements IssueRepository {
  final IssueApiService apiService;

  IssueRepositoryImpl({required this.apiService});

  @override
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
  }) {
    return apiService.getIssues(
      categoryId: categoryId,
      statusId: statusId,
      territoryId: territoryId,
      severity: severity,
      visibility: visibility,
      departmentId: departmentId,
      userId: userId,
      keyword: keyword,
      page: page,
      size: size,
      sortBy: sortBy,
      sortDir: sortDir,
    );
  }

  @override
  Future<IssueModel> getIssueById(int id) => apiService.getIssueById(id);

  @override
  Future<IssueModel> createIssue(Map<String, dynamic> body) => apiService.createIssue(body);

  @override
  Future<IssueModel> updateIssue(int id, Map<String, dynamic> body) => apiService.updateIssue(id, body);

  @override
  Future<void> deleteIssue(int id) => apiService.deleteIssue(id);

  @override
  Future<List<CategoryModel>> getCategories() => apiService.getCategories();

  @override
  Future<List<TerritoryModel>> getTerritories() => apiService.getTerritories();

  @override
  Future<List<DepartmentModel>> getDepartments({int? territoryId}) => apiService.getDepartments(territoryId: territoryId);

  @override
  Future<List<StatusModel>> getStatuses() => apiService.getStatuses();

  @override
  Future<List<CommentModel>> getComments(int issueId) => apiService.getComments(issueId);

  @override
  Future<CommentModel> addComment(int issueId, String text) => apiService.addComment(issueId, text);

  @override
  Future<void> deleteComment(int commentId) => apiService.deleteComment(commentId);

  @override
  Future<void> addUpvote(int issueId) => apiService.addUpvote(issueId);

  @override
  Future<void> removeUpvote(int issueId) => apiService.removeUpvote(issueId);

  @override
  Future<bool> getUpvoteStatus(int issueId) => apiService.getUpvoteStatus(issueId);

  @override
  Future<List<IssueImageModel>> getIssueImages(int issueId) => apiService.getIssueImages(issueId);

  @override
  Future<IssueImageModel> addImageToIssue(int issueId, String imageUrl, {String? filename}) =>
      apiService.addImageToIssue(issueId, imageUrl, filename: filename);

  @override
  Future<void> deleteIssueImage(int issueId, int imageId) => apiService.deleteIssueImage(issueId, imageId);
}
