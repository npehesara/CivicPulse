package civicpulse_backend.dto.issue;

import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.Severity;
import civicpulse_backend.entity.Visibility;

import java.time.LocalDateTime;

public class IssueResponse {

    private Long issueId;
    private String title;
    private String description;
    private Double latitude;
    private Double longitude;
    private String locationPoint;
    private Visibility visibility;
    private Severity severity;
    private Boolean isTransitReport;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private Long userId;
    private String userFullName;
    private String userEmail;

    private Long categoryId;
    private String categoryName;

    private Long territoryId;
    private String territoryName;

    private Long departmentId;
    private String departmentName;

    private Long statusId;
    private String statusName;

    private Long upvoteCount;
    private Long commentCount;

    public IssueResponse() {
    }

    public static IssueResponse fromEntity(Issue issue) {
        return fromEntity(issue, 0L, 0L);
    }

    public static IssueResponse fromEntity(Issue issue, Long upvoteCount, Long commentCount) {
        if (issue == null) return null;
        IssueResponse response = new IssueResponse();
        response.setIssueId(issue.getIssueId());
        response.setTitle(issue.getTitle());
        response.setDescription(issue.getDescription());
        response.setLatitude(issue.getLatitude());
        response.setLongitude(issue.getLongitude());
        response.setLocationPoint(issue.getLocationPoint());
        response.setVisibility(issue.getVisibility());
        response.setSeverity(issue.getSeverity());
        response.setIsTransitReport(issue.getIsTransitReport());
        response.setCreatedAt(issue.getCreatedAt());
        response.setUpdatedAt(issue.getUpdatedAt());

        if (issue.getUser() != null) {
            response.setUserId(issue.getUser().getUserId());
            response.setUserFullName(issue.getUser().getFullName());
            response.setUserEmail(issue.getUser().getEmail());
        }

        if (issue.getCategory() != null) {
            response.setCategoryId(issue.getCategory().getCategoryId());
            response.setCategoryName(issue.getCategory().getCategoryName());
        }

        if (issue.getTerritory() != null) {
            response.setTerritoryId(issue.getTerritory().getTerritoryId());
            response.setTerritoryName(issue.getTerritory().getTerritoryName());
        }

        if (issue.getDepartment() != null) {
            response.setDepartmentId(issue.getDepartment().getDepartmentId());
            response.setDepartmentName(issue.getDepartment().getDepartmentName());
        }

        if (issue.getStatus() != null) {
            response.setStatusId(issue.getStatus().getStatusId());
            response.setStatusName(issue.getStatus().getStatusName());
        }

        response.setUpvoteCount(upvoteCount != null ? upvoteCount : 0L);
        response.setCommentCount(commentCount != null ? commentCount : 0L);

        return response;
    }

    // Getters and Setters

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public String getLocationPoint() {
        return locationPoint;
    }

    public void setLocationPoint(String locationPoint) {
        this.locationPoint = locationPoint;
    }

    public Visibility getVisibility() {
        return visibility;
    }

    public void setVisibility(Visibility visibility) {
        this.visibility = visibility;
    }

    public Severity getSeverity() {
        return severity;
    }

    public void setSeverity(Severity severity) {
        this.severity = severity;
    }

    public Boolean getIsTransitReport() {
        return isTransitReport;
    }

    public void setIsTransitReport(Boolean isTransitReport) {
        this.isTransitReport = isTransitReport;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
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

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public Long getTerritoryId() {
        return territoryId;
    }

    public void setTerritoryId(Long territoryId) {
        this.territoryId = territoryId;
    }

    public String getTerritoryName() {
        return territoryName;
    }

    public void setTerritoryName(String territoryName) {
        this.territoryName = territoryName;
    }

    public Long getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Long departmentId) {
        this.departmentId = departmentId;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public Long getStatusId() {
        return statusId;
    }

    public void setStatusId(Long statusId) {
        this.statusId = statusId;
    }

    public String getStatusName() {
        return statusName;
    }

    public void setStatusName(String statusName) {
        this.statusName = statusName;
    }

    public Long getUpvoteCount() {
        return upvoteCount;
    }

    public void setUpvoteCount(Long upvoteCount) {
        this.upvoteCount = upvoteCount;
    }

    public Long getCommentCount() {
        return commentCount;
    }

    public void setCommentCount(Long commentCount) {
        this.commentCount = commentCount;
    }
}
