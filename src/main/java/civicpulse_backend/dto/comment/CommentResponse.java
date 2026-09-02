package civicpulse_backend.dto.comment;

import civicpulse_backend.entity.Comment;
import java.time.LocalDateTime;

public class CommentResponse {

    private Long commentId;
    private String commentText;
    private LocalDateTime createdAt;
    private Long userId;
    private String userFullName;
    private String userProfileImage;
    private Long issueId;

    public CommentResponse() {
    }

    public static CommentResponse fromEntity(Comment comment) {
        if (comment == null) return null;
        CommentResponse response = new CommentResponse();
        response.setCommentId(comment.getCommentId());
        response.setCommentText(comment.getCommentText());
        response.setCreatedAt(comment.getCreatedAt());

        if (comment.getUser() != null) {
            response.setUserId(comment.getUser().getUserId());
            response.setUserFullName(comment.getUser().getFullName());
            response.setUserProfileImage(comment.getUser().getProfileImage());
        }

        if (comment.getIssue() != null) {
            response.setIssueId(comment.getIssue().getIssueId());
        }

        return response;
    }

    public Long getCommentId() {
        return commentId;
    }

    public void setCommentId(Long commentId) {
        this.commentId = commentId;
    }

    public String getCommentText() {
        return commentText;
    }

    public void setCommentText(String commentText) {
        this.commentText = commentText;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUserFullName() {
        return userFullName;
    }

    public void setUserFullName(String userFullName) {
        this.userFullName = userFullName;
    }

    public String getUserProfileImage() {
        return userProfileImage;
    }

    public void setUserProfileImage(String userProfileImage) {
        this.userProfileImage = userProfileImage;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }
}
