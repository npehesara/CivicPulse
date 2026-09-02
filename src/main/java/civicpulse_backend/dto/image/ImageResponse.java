package civicpulse_backend.dto.image;

import civicpulse_backend.entity.IssueImage;
import civicpulse_backend.entity.ModerationStatus;

import java.time.LocalDateTime;

public class ImageResponse {

    private Long imageId;
    private String imageUrl;
    private Double aiSafetyScore;
    private Double aiRelevanceScore;
    private ModerationStatus moderationStatus;
    private Boolean isAnonymized;
    private String originalFilename;
    private LocalDateTime uploadedAt;
    private Long issueId;

    public ImageResponse() {
    }

    public static ImageResponse fromEntity(IssueImage image) {
        if (image == null) return null;
        ImageResponse response = new ImageResponse();
        response.setImageId(image.getImageId());
        response.setImageUrl(image.getImageUrl());
        response.setAiSafetyScore(image.getAiSafetyScore());
        response.setAiRelevanceScore(image.getAiRelevanceScore());
        response.setModerationStatus(image.getModerationStatus());
        response.setIsAnonymized(image.getIsAnonymized());
        response.setOriginalFilename(image.getOriginalFilename());
        response.setUploadedAt(image.getUploadedAt());
        if (image.getIssue() != null) {
            response.setIssueId(image.getIssue().getIssueId());
        }
        return response;
    }

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

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }
}
