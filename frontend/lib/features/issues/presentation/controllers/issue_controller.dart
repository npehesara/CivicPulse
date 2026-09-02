import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/issue_model.dart';
import '../../data/models/status_model.dart';
import '../../data/models/territory_model.dart';
import '../../data/repositories/issue_repository.dart';

enum FeedTab { all, territory, nearby }

class IssueController extends ChangeNotifier {
  final IssueRepository issueRepository;

  IssueController({required this.issueRepository});

  List<IssueModel> _issues = [];
  List<CategoryModel> _categories = [];
  List<TerritoryModel> _territories = [];
  List<StatusModel> _statuses = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  FeedTab _selectedTab = FeedTab.all;
  int? _selectedCategoryId;
  int? _selectedTerritoryId;
  int? _selectedStatusId;
  String? _selectedSeverity;
  String? _searchKeyword;

  List<IssueModel> get issues => _issues;
  List<CategoryModel> get categories => _categories;
  List<TerritoryModel> get territories => _territories;
  List<StatusModel> get statuses => _statuses;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  FeedTab get selectedTab => _selectedTab;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedTerritoryId => _selectedTerritoryId;
  int? get selectedStatusId => _selectedStatusId;
  String? get selectedSeverity => _selectedSeverity;
  String? get searchKeyword => _searchKeyword;

  Future<void> init(UserModel? currentUser) async {
    await loadFilterMetadata();
    await loadFeed(currentUser: currentUser);
  }

  Future<void> loadFilterMetadata() async {
    try {
      final cats = await issueRepository.getCategories();
      final terrs = await issueRepository.getTerritories();
      final stats = await issueRepository.getStatuses();
      _categories = cats;
      _territories = terrs;
      _statuses = stats;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setTab(FeedTab tab, {UserModel? currentUser}) async {
    _selectedTab = tab;
    notifyListeners();
    await loadFeed(currentUser: currentUser);
  }

  void setCategoryFilter(int? catId, {UserModel? currentUser}) {
    _selectedCategoryId = catId;
    loadFeed(currentUser: currentUser);
  }

  void setSeverityFilter(String? severity, {UserModel? currentUser}) {
    _selectedSeverity = severity;
    loadFeed(currentUser: currentUser);
  }

  void setStatusFilter(int? statusId, {UserModel? currentUser}) {
    _selectedStatusId = statusId;
    loadFeed(currentUser: currentUser);
  }

  void setSearchKeyword(String? keyword, {UserModel? currentUser}) {
    _searchKeyword = keyword;
    loadFeed(currentUser: currentUser);
  }

  void clearFilters({UserModel? currentUser}) {
    _selectedCategoryId = null;
    _selectedTerritoryId = null;
    _selectedStatusId = null;
    _selectedSeverity = null;
    _searchKeyword = null;
    loadFeed(currentUser: currentUser);
  }

  Future<void> loadFeed({UserModel? currentUser, bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      int? effectiveTerritoryId = _selectedTerritoryId;

      if (_selectedTab == FeedTab.territory && currentUser?.registeredTerritoryId != null) {
        effectiveTerritoryId = currentUser!.registeredTerritoryId;
      }

      final fetchedIssues = await issueRepository.getIssues(
        categoryId: _selectedCategoryId,
        statusId: _selectedStatusId,
        territoryId: effectiveTerritoryId,
        severity: _selectedSeverity,
        keyword: _searchKeyword,
        size: 50,
      );

      _issues = fetchedIssues;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load issues. Please check your connection.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> toggleUpvote(IssueModel issue) async {
    final index = _issues.indexWhere((i) => i.issueId == issue.issueId);
    if (index == -1) return;

    final currentHasUpvoted = issue.hasUpvoted;
    final newCount = currentHasUpvoted ? (issue.upvoteCount - 1).clamp(0, 999999) : issue.upvoteCount + 1;
    final updated = issue.copyWith(hasUpvoted: !currentHasUpvoted, upvoteCount: newCount);

    _issues[index] = updated;
    notifyListeners();

    try {
      if (currentHasUpvoted) {
        await issueRepository.removeUpvote(issue.issueId);
      } else {
        await issueRepository.addUpvote(issue.issueId);
      }
    } catch (_) {
      // Revert on error
      if (index < _issues.length) {
        _issues[index] = issue;
        notifyListeners();
      }
    }
  }
}
