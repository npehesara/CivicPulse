package civicpulse_backend.dto.auth;

import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;

import java.time.LocalDateTime;

public class UserResponse {

    private Long userId;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String profileImage;
    private Role role;
    private AccountStatus accountStatus;
    private Long registeredTerritoryId;
    private String registeredTerritoryName;
    private LocalDateTime createdAt;

    public UserResponse() {
    }

    public UserResponse(Long userId, String fullName, String email, String phoneNumber, String profileImage,
                        Role role, AccountStatus accountStatus, LocalDateTime createdAt) {
        this(userId, fullName, email, phoneNumber, profileImage, role, accountStatus, null, null, createdAt);
    }

    public UserResponse(Long userId, String fullName, String email, String phoneNumber, String profileImage,
                        Role role, AccountStatus accountStatus, Long registeredTerritoryId,
                        String registeredTerritoryName, LocalDateTime createdAt) {
        this.userId = userId;
        this.fullName = fullName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.profileImage = profileImage;
        this.role = role;
        this.accountStatus = accountStatus;
        this.registeredTerritoryId = registeredTerritoryId;
        this.registeredTerritoryName = registeredTerritoryName;
        this.createdAt = createdAt;
    }

    public static UserResponse fromEntity(User user) {
        return fromEntity(user, null);
    }

    public static UserResponse fromEntity(User user, String territoryName) {
        if (user == null) {
            return null;
        }
        return new UserResponse(
                user.getUserId(),
                user.getFullName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getProfileImage(),
                user.getRole(),
                user.getAccountStatus(),
                user.getRegisteredTerritoryId(),
                territoryName,
                user.getCreatedAt()
        );
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
}
