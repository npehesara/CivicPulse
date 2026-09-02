package civicpulse_backend.dto.resolution;

import civicpulse_backend.entity.Resolution;
import java.time.LocalDateTime;

public class ResolutionResponse {

    private Long resolutionId;
    private Long issueId;
    private String resolutionDescription;
    private String resolutionImage;
    private LocalDateTime resolvedAt;
    private Long resolvedByUserId;
    private String resolvedByUserName;
    private String resolvedByUserEmail;

    public ResolutionResponse() {
    }

    public static ResolutionResponse fromEntity(Resolution resolution) {
        if (resolution == null) return null;
        ResolutionResponse response = new ResolutionResponse();
        response.setResolutionId(resolution.getResolutionId());
        if (resolution.getIssue() != null) {
            response.setIssueId(resolution.getIssue().getIssueId());
        }
        response.setResolutionDescription(resolution.getResolutionDescription());
        response.setResolutionImage(resolution.getResolutionImage());
        response.setResolvedAt(resolution.getResolvedAt());
        if (resolution.getResolvedBy() != null) {
            response.setResolvedByUserId(resolution.getResolvedBy().getUserId());
            response.setResolvedByUserName(resolution.getResolvedBy().getFullName());
            response.setResolvedByUserEmail(resolution.getResolvedBy().getEmail());
        }
        return response;
    }

    public Long getResolutionId() {
        return resolutionId;
    }

    public void setResolutionId(Long resolutionId) {
        this.resolutionId = resolutionId;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }

    public String getResolutionDescription() {
        return resolutionDescription;
    }

    public void setResolutionDescription(String resolutionDescription) {
        this.resolutionDescription = resolutionDescription;
    }

    public String getResolutionImage() {
        return resolutionImage;
    }

    public void setResolutionImage(String resolutionImage) {
        this.resolutionImage = resolutionImage;
    }

    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }

    public void setResolvedAt(LocalDateTime resolvedAt) {
        this.resolvedAt = resolvedAt;
    }

    public Long getResolvedByUserId() {
        return resolvedByUserId;
    }

    public void setResolvedByUserId(Long resolvedByUserId) {
        this.resolvedByUserId = resolvedByUserId;
    }

    public String getResolvedByUserName() {
        return resolvedByUserName;
    }

    public void setResolvedByUserName(String resolvedByUserName) {
        this.resolvedByUserName = resolvedByUserName;
    }

    public String getResolvedByUserEmail() {
        return resolvedByUserEmail;
    }

    public void setResolvedByUserEmail(String resolvedByUserEmail) {
        this.resolvedByUserEmail = resolvedByUserEmail;
    }
}
