package civicpulse_backend.dto.user;

import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;

import java.time.LocalDateTime;

public class PublicUserResponse {

    private Long userId;
    private String fullName;
    private String profileImage;
    private Role role;
    private Long registeredTerritoryId;
    private String registeredTerritoryName;
    private LocalDateTime createdAt;
    private Long publicIssuesCount;

    public PublicUserResponse() {
    }

    public static PublicUserResponse fromEntity(User user) {
        return fromEntity(user, null, 0L);
    }

    public static PublicUserResponse fromEntity(User user, String territoryName, Long publicIssuesCount) {
        if (user == null) return null;
        PublicUserResponse response = new PublicUserResponse();
        response.setUserId(user.getUserId());
        response.setFullName(user.getFullName());
        response.setProfileImage(user.getProfileImage());
        response.setRole(user.getRole());
        response.setRegisteredTerritoryId(user.getRegisteredTerritoryId());
        response.setRegisteredTerritoryName(territoryName);
        response.setCreatedAt(user.getCreatedAt());
        response.setPublicIssuesCount(publicIssuesCount != null ? publicIssuesCount : 0L);
        return response;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getProfileImage() {
        return profileImage;
    }

    public void setProfileImage(String profileImage) {
        this.profileImage = profileImage;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Long getRegisteredTerritoryId() {
        return registeredTerritoryId;
    }

    public void setRegisteredTerritoryId(Long registeredTerritoryId) {
        this.registeredTerritoryId = registeredTerritoryId;
    }

    public String getRegisteredTerritoryName() {
        return registeredTerritoryName;
    }

    public void setRegisteredTerritoryName(String registeredTerritoryName) {
        this.registeredTerritoryName = registeredTerritoryName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Long getPublicIssuesCount() {
        return publicIssuesCount;
    }

    public void setPublicIssuesCount(Long publicIssuesCount) {
        this.publicIssuesCount = publicIssuesCount;
    }
}
