package civicpulse_backend.service;

import civicpulse_backend.dto.comment.CreateCommentRequest;
import civicpulse_backend.dto.comment.CommentResponse;
import civicpulse_backend.entity.Comment;
import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.NotificationType;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.CommentRepository;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CommentService {

    private final CommentRepository commentRepository;
    private final IssueRepository issueRepository;
    private final NotificationService notificationService;
    private final SecurityUtils securityUtils;

    public CommentService(CommentRepository commentRepository,
                          IssueRepository issueRepository,
                          NotificationService notificationService,
                          SecurityUtils securityUtils) {
        this.commentRepository = commentRepository;
        this.issueRepository = issueRepository;
        this.notificationService = notificationService;
        this.securityUtils = securityUtils;
    }

    @Transactional
    public CommentResponse addComment(Long issueId, CreateCommentRequest request) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + issueId));

        User currentUser = securityUtils.getCurrentUser();

        Comment comment = new Comment();
        comment.setCommentText(request.getCommentText().trim());
        comment.setIssue(issue);
        comment.setUser(currentUser);
        comment.setIsDeleted(false);
        comment.setCreatedAt(LocalDateTime.now());

        Comment saved = commentRepository.save(comment);

        // Notify issue owner if comment is made by someone else
        if (!issue.getUser().getUserId().equals(currentUser.getUserId())) {
            notificationService.createNotification(
                    issue.getUser(),
                    issue,
                    "New Comment on Issue",
                    currentUser.getFullName() + " commented on your issue '" + issue.getTitle() + "'",
                    NotificationType.COMMENT_ADDED
            );
        }

        return CommentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<CommentResponse> getCommentsForIssue(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        return commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(issueId).stream()
                .map(CommentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteComment(Long commentId) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found with id: " + commentId));

        User currentUser = securityUtils.getCurrentUser();
        boolean isOwner = comment.getUser().getUserId().equals(currentUser.getUserId());
        boolean isStaff = currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.OFFICIAL;

        if (!isOwner && !isStaff) {
            throw new UnauthorizedOperationException("You do not have permission to delete this comment");
        }

        // Soft delete
        comment.setIsDeleted(true);
        commentRepository.save(comment);
    }
}
