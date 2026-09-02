package civicpulse_backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "moderations")
public class Moderation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "moderation_id")
    private Long moderationId;

    @Column(name = "toxicity_score")
    private Double toxicityScore;

    @Column(name = "spam_score")
    private Double spamScore;

    @Column(name = "privacy_detected", nullable = false)
    private Boolean privacyDetected = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "text_moderation_status", nullable = false)
    private ModerationStatus textModerationStatus = ModerationStatus.PENDING;

    @Column(name = "reviewed_by")
    private Long reviewedBy;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issue_id", unique = true, nullable = false)
    private Issue issue;

    public Moderation() {
    }

    public Moderation(Issue issue) {
        this.issue = issue;
    }

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.privacyDetected == null) {
            this.privacyDetected = false;
        }
        if (this.textModerationStatus == null) {
            this.textModerationStatus = ModerationStatus.PENDING;
        }
    }

    // Getters and Setters

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

    public Issue getIssue() {
        return issue;
    }

    public void setIssue(Issue issue) {
        this.issue = issue;
    }
}
