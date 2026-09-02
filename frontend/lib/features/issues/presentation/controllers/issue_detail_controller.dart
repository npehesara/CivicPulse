import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/issue_model.dart';
import '../../data/repositories/issue_repository.dart';

class IssueDetailController extends ChangeNotifier {
  final IssueRepository issueRepository;
  final int issueId;

  IssueDetailController({
    required this.issueRepository,
    required this.issueId,
  });

  IssueModel? _issue;
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isSubmittingComment = false;
  String? _errorMessage;

  IssueModel? get issue => _issue;
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isSubmittingComment => _isSubmittingComment;
  String? get errorMessage => _errorMessage;

  Future<void> loadDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedIssue = await issueRepository.getIssueById(issueId);
      final fetchedComments = await issueRepository.getComments(issueId);
      _issue = fetchedIssue;
      _comments = fetchedComments;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load issue details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUpvote() async {
    if (_issue == null) return;
    final currentHasUpvoted = _issue!.hasUpvoted;
    final newCount = currentHasUpvoted ? (_issue!.upvoteCount - 1).clamp(0, 999999) : _issue!.upvoteCount + 1;

    _issue = _issue!.copyWith(hasUpvoted: !currentHasUpvoted, upvoteCount: newCount);
    notifyListeners();

    try {
      if (currentHasUpvoted) {
        await issueRepository.removeUpvote(issueId);
      } else {
        await issueRepository.addUpvote(issueId);
      }
    } catch (_) {
      // Revert
      _issue = _issue!.copyWith(hasUpvoted: currentHasUpvoted, upvoteCount: _issue!.upvoteCount);
      notifyListeners();
    }
  }

  Future<bool> addComment(String text) async {
    if (text.trim().isEmpty) return false;
    _isSubmittingComment = true;
    notifyListeners();

    try {
      final newComment = await issueRepository.addComment(issueId, text.trim());
      _comments = [..._comments, newComment];
      if (_issue != null) {
        _issue = _issue!.copyWith(commentCount: _issue!.commentCount + 1);
      }
      _isSubmittingComment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmittingComment = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      await issueRepository.deleteComment(commentId);
      _comments.removeWhere((c) => c.commentId == commentId);
      if (_issue != null && _issue!.commentCount > 0) {
        _issue = _issue!.copyWith(commentCount: _issue!.commentCount - 1);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteIssue() async {
    try {
      await issueRepository.deleteIssue(issueId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
