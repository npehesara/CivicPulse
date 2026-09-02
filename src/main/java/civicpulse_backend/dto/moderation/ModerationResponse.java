package civicpulse_backend.dto.moderation;

import civicpulse_backend.entity.Moderation;
import civicpulse_backend.entity.ModerationStatus;

import java.time.LocalDateTime;

public class ModerationResponse {

    private Long moderationId;
    private Double toxicityScore;
    private Double spamScore;
    private Boolean privacyDetected;
    private ModerationStatus textModerationStatus;
    private Long reviewedBy;
    private LocalDateTime reviewedAt;
    private LocalDateTime createdAt;
    private Long issueId;

    public ModerationResponse() {
    }

    public static ModerationResponse fromEntity(Moderation moderation) {
        if (moderation == null) return null;
        ModerationResponse response = new ModerationResponse();
        response.setModerationId(moderation.getModerationId());
        response.setToxicityScore(moderation.getToxicityScore());
        response.setSpamScore(moderation.getSpamScore());
        response.setPrivacyDetected(moderation.getPrivacyDetected());
        response.setTextModerationStatus(moderation.getTextModerationStatus());
        response.setReviewedBy(moderation.getReviewedBy());
        response.setReviewedAt(moderation.getReviewedAt());
        response.setCreatedAt(moderation.getCreatedAt());
        if (moderation.getIssue() != null) {
            response.setIssueId(moderation.getIssue().getIssueId());
        }
        return response;
    }

    public Long getModerationId() {
        return moderationId;
    }

    public void setModerationId(Long moderationId) {
        this.moderationId = moderationId;
    }

    public Double getToxicityScore() {
        return toxicityScore;
    }

    public void setToxicityScore(Double toxicityScore) {
        this.toxicityScore = toxicityScore;
    }

    public Double getSpamScore() {
        return spamScore;
    }

    public void setSpamScore(Double spamScore) {
        this.spamScore = spamScore;
    }

    public Boolean getPrivacyDetected() {
        return privacyDetected;
    }

    public void setPrivacyDetected(Boolean privacyDetected) {
        this.privacyDetected = privacyDetected;
    }

    public ModerationStatus getTextModerationStatus() {
        return textModerationStatus;
    }

    public void setTextModerationStatus(ModerationStatus textModerationStatus) {
        this.textModerationStatus = textModerationStatus;
    }

    public Long getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(Long reviewedBy) {
        this.reviewedBy = reviewedBy;
    }

    public LocalDateTime getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(LocalDateTime reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }
}
