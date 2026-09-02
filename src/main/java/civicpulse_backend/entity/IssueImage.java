package civicpulse_backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "issue_images")
public class IssueImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "image_id")
    private Long imageId;

    @Column(name = "image_url", nullable = false)
    private String imageUrl;

    @Column(name = "ai_safety_score")
    private Double aiSafetyScore;

    @Column(name = "ai_relevance_score")
    private Double aiRelevanceScore;

    @Enumerated(EnumType.STRING)
    @Column(name = "moderation_status", nullable = false)
    private ModerationStatus moderationStatus = ModerationStatus.APPROVED;

    @Column(name = "is_anonymized", nullable = false)
    private Boolean isAnonymized = false;

    @Column(name = "original_filename")
    private String originalFilename;

    @Column(name = "uploaded_at", nullable = false, updatable = false)
    private LocalDateTime uploadedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    public IssueImage() {
    }

    public IssueImage(String imageUrl, String originalFilename, Issue issue) {
        this.imageUrl = imageUrl;
        this.originalFilename = originalFilename;
        this.issue = issue;
    }

    @PrePersist
    protected void onCreate() {
        if (this.uploadedAt == null) {
            this.uploadedAt = LocalDateTime.now();
        }
        if (this.moderationStatus == null) {
            this.moderationStatus = ModerationStatus.APPROVED;
        }
        if (this.isAnonymized == null) {
            this.isAnonymized = false;
        }
    }

    // Getters and Setters

    public Long getImageId() {
        return imageId;
    }

    public void setImageId(Long imageId) {
        this.imageId = imageId;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Double getAiSafetyScore() {
        return aiSafetyScore;
    }

    public void setAiSafetyScore(Double aiSafetyScore) {
        this.aiSafetyScore = aiSafetyScore;
    }

    public Double getAiRelevanceScore() {
        return aiRelevanceScore;
    }

    public void setAiRelevanceScore(Double aiRelevanceScore) {
        this.aiRelevanceScore = aiRelevanceScore;
    }

    public ModerationStatus getModerationStatus() {
        return moderationStatus;
    }

    public void setModerationStatus(ModerationStatus moderationStatus) {
        this.moderationStatus = moderationStatus;
    }

    public Boolean getIsAnonymized() {
        return isAnonymized;
    }

    public void setIsAnonymized(Boolean isAnonymized) {
        this.isAnonymized = isAnonymized;
    }

    public String getOriginalFilename() {
        return originalFilename;
    }

    public void setOriginalFilename(String originalFilename) {
        this.originalFilename = originalFilename;
    }

    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }

    public void setUploadedAt(LocalDateTime uploadedAt) {
        this.uploadedAt = uploadedAt;
    }

    public Issue getIssue() {
        return issue;
    }

    public void setIssue(Issue issue) {
        this.issue = issue;
    }
}
