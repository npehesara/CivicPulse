package civicpulse_backend.dto.user;

import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;

import java.time.LocalDateTime;

public class UserProfileResponse {

    private Long userId;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String profileImage;
    private Role role;
    private AccountStatus accountStatus;
    private Long registeredTerritoryId;
    private String registeredTerritoryName;
    private Long territoryId;
    private String territoryName;
    private Double homeLatitude;
    private Double homeLongitude;
    private LocalDateTime createdAt;
    private Long reportedIssuesCount;
    private Long upvotesGivenCount;

    public UserProfileResponse() {
    }

    public static UserProfileResponse fromEntity(User user) {
        return fromEntity(user, null, 0L, 0L);
    }

    public static UserProfileResponse fromEntity(User user, String territoryName, Long reportedCount, Long upvoteCount) {
        if (user == null) return null;
        UserProfileResponse response = new UserProfileResponse();
        response.setUserId(user.getUserId());
        response.setFullName(user.getFullName());
        response.setEmail(user.getEmail());
        response.setPhoneNumber(user.getPhoneNumber());
        response.setProfileImage(user.getProfileImage());
        response.setRole(user.getRole());
        response.setAccountStatus(user.getAccountStatus());
        response.setTerritoryId(user.getTerritoryId());
        response.setRegisteredTerritoryId(user.getTerritoryId());
        response.setTerritoryName(territoryName);
        response.setRegisteredTerritoryName(territoryName);
        response.setHomeLatitude(user.getHomeLatitude());
        response.setHomeLongitude(user.getHomeLongitude());
        response.setCreatedAt(user.getCreatedAt());
        response.setReportedIssuesCount(reportedCount != null ? reportedCount : 0L);
        response.setUpvotesGivenCount(upvoteCount != null ? upvoteCount : 0L);
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

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
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

    public AccountStatus getAccountStatus() {
        return accountStatus;
    }

    public void setAccountStatus(AccountStatus accountStatus) {
        this.accountStatus = accountStatus;
    }

    public Long getRegisteredTerritoryId() {
        return registeredTerritoryId != null ? registeredTerritoryId : territoryId;
    }

    public void setRegisteredTerritoryId(Long registeredTerritoryId) {
        this.registeredTerritoryId = registeredTerritoryId;
        if (this.territoryId == null) {
            this.territoryId = registeredTerritoryId;
        }
    }

    public String getRegisteredTerritoryName() {
        return registeredTerritoryName != null ? registeredTerritoryName : territoryName;
    }

    public void setRegisteredTerritoryName(String registeredTerritoryName) {
        this.registeredTerritoryName = registeredTerritoryName;
        if (this.territoryName == null) {
            this.territoryName = registeredTerritoryName;
        }
    }

    public Long getTerritoryId() {
        return territoryId != null ? territoryId : registeredTerritoryId;
    }

    public void setTerritoryId(Long territoryId) {
        this.territoryId = territoryId;
        if (this.registeredTerritoryId == null) {
            this.registeredTerritoryId = territoryId;
        }
    }

    public String getTerritoryName() {
        return territoryName != null ? territoryName : registeredTerritoryName;
    }

    public void setTerritoryName(String territoryName) {
        this.territoryName = territoryName;
        if (this.registeredTerritoryName == null) {
            this.registeredTerritoryName = territoryName;
        }
    }

    public Double getHomeLatitude() {
        return homeLatitude;
    }

    public void setHomeLatitude(Double homeLatitude) {
        this.homeLatitude = homeLatitude;
    }

    public Double getHomeLongitude() {
        return homeLongitude;
    }

    public void setHomeLongitude(Double homeLongitude) {
        this.homeLongitude = homeLongitude;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Long getReportedIssuesCount() {
        return reportedIssuesCount;
    }

    public void setReportedIssuesCount(Long reportedIssuesCount) {
        this.reportedIssuesCount = reportedIssuesCount;
    }

    public Long getUpvotesGivenCount() {
        return upvotesGivenCount;
    }

    public void setUpvotesGivenCount(Long upvotesGivenCount) {
        this.upvotesGivenCount = upvotesGivenCount;
    }
}
