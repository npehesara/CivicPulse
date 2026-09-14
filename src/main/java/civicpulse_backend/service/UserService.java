package civicpulse_backend.service;

import civicpulse_backend.dto.image.CloudinaryUploadResult;
import civicpulse_backend.dto.user.ChangePasswordRequest;
import civicpulse_backend.dto.user.PublicUserResponse;
import civicpulse_backend.dto.user.UpdateProfileRequest;
import civicpulse_backend.dto.user.UserProfileResponse;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.entity.User;
import civicpulse_backend.entity.Visibility;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.TerritoryRepository;
import civicpulse_backend.repository.UpvoteRepository;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.SecurityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final TerritoryRepository territoryRepository;
    private final IssueRepository issueRepository;
    private final UpvoteRepository upvoteRepository;
    private final SecurityUtils securityUtils;
    private final CloudinaryService cloudinaryService;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository,
                       TerritoryRepository territoryRepository,
                       IssueRepository issueRepository,
                       UpvoteRepository upvoteRepository,
                       SecurityUtils securityUtils,
                       CloudinaryService cloudinaryService,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.territoryRepository = territoryRepository;
        this.issueRepository = issueRepository;
        this.upvoteRepository = upvoteRepository;
        this.securityUtils = securityUtils;
        this.cloudinaryService = cloudinaryService;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getCurrentUserProfile() {
        User currentUser = securityUtils.getCurrentUser();
        return buildUserProfileResponse(currentUser);
    }

    @Transactional
    public UserProfileResponse updateCurrentUserProfile(UpdateProfileRequest request) {
        User currentUser = securityUtils.getCurrentUser();

        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            currentUser.setFullName(request.getFullName().trim());
        }

        if (request.getPhoneNumber() != null) {
            currentUser.setPhoneNumber(request.getPhoneNumber().trim());
        }

        if (request.getProfileImage() != null) {
            currentUser.setProfileImage(request.getProfileImage().trim());
        }

        if (request.getHomeLatitude() != null) {
            currentUser.setHomeLatitude(request.getHomeLatitude());
        }

        if (request.getHomeLongitude() != null) {
            currentUser.setHomeLongitude(request.getHomeLongitude());
        }

        Long terrId = request.getTerritoryId() != null ? request.getTerritoryId() : request.getRegisteredTerritoryId();
        if (terrId != null) {
            if (terrId > 0) {
                Territory territory = territoryRepository.findById(terrId)
                        .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + terrId));
                currentUser.setTerritoryId(territory.getTerritoryId());
            } else {
                currentUser.setTerritoryId(null);
            }
        }

        User saved = userRepository.save(currentUser);
        return buildUserProfileResponse(saved);
    }

    @Transactional
    public UserProfileResponse updateProfileImage(MultipartFile file) {
        User currentUser = securityUtils.getCurrentUser();
        String oldImageUrl = currentUser.getProfileImage();

        CloudinaryUploadResult uploadResult = cloudinaryService.uploadProfileImage(file);
        currentUser.setProfileImage(uploadResult.secureUrl());

        User savedUser;
        try {
            savedUser = userRepository.save(currentUser);
        } catch (Exception ex) {
            try {
                cloudinaryService.deleteImage(uploadResult.publicId());
            } catch (Exception cleanupEx) {
                log.error("Failed to clean up Cloudinary image on DB failure [{}]: {}", uploadResult.publicId(), cleanupEx.getMessage());
            }
            throw ex;
        }

        // Safely delete previous Cloudinary image if it existed in civicpulse
        if (oldImageUrl != null && !oldImageUrl.isBlank()) {
            String oldPublicId = extractPublicId(oldImageUrl);
            if (oldPublicId != null) {
                try {
                    cloudinaryService.deleteImage(oldPublicId);
                } catch (Exception ex) {
                    log.warn("Failed to delete previous profile image from Cloudinary [publicId: {}]: {}", oldPublicId, ex.getMessage());
                }
            }
        }

        return buildUserProfileResponse(savedUser);
    }

    @Transactional
    public UserProfileResponse deleteProfileImage() {
        User currentUser = securityUtils.getCurrentUser();
        String oldImageUrl = currentUser.getProfileImage();

        currentUser.setProfileImage(null);
        User savedUser = userRepository.save(currentUser);

        if (oldImageUrl != null && !oldImageUrl.isBlank()) {
            String oldPublicId = extractPublicId(oldImageUrl);
            if (oldPublicId != null) {
                try {
                    cloudinaryService.deleteImage(oldPublicId);
                } catch (Exception ex) {
                    log.warn("Failed to delete profile image from Cloudinary [publicId: {}]: {}", oldPublicId, ex.getMessage());
                }
            }
        }

        return buildUserProfileResponse(savedUser);
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        User currentUser = securityUtils.getCurrentUser();

        if (request.getCurrentPassword() == null || request.getCurrentPassword().isBlank()) {
            throw new IllegalArgumentException("Current password is required");
        }

        if (!passwordEncoder.matches(request.getCurrentPassword(), currentUser.getPasswordHash())) {
            throw new InvalidCredentialsException("Current password is incorrect");
        }

        if (request.getNewPassword() == null || request.getNewPassword().length() < 8) {
            throw new IllegalArgumentException("New password must be at least 8 characters");
        }

        if (request.getConfirmPassword() != null && !request.getConfirmPassword().isBlank()
                && !request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("New password and confirm password do not match");
        }

        if (passwordEncoder.matches(request.getNewPassword(), currentUser.getPasswordHash())) {
            throw new IllegalArgumentException("New password must be different from current password");
        }

        currentUser.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(currentUser);
    }

    private String extractPublicId(String url) {
        if (url == null || url.isBlank()) {
            return null;
        }
        int prefixIndex = url.indexOf("civicpulse/");
        if (prefixIndex == -1) {
            return null;
        }
        String path = url.substring(prefixIndex);
        int queryIndex = path.indexOf('?');
        if (queryIndex != -1) {
            path = path.substring(0, queryIndex);
        }
        int lastDot = path.lastIndexOf('.');
        return lastDot > 0 ? path.substring(0, lastDot) : path;
    }

    @Transactional(readOnly = true)
    public PublicUserResponse getPublicUserProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        String territoryName = null;
        if (user.getRegisteredTerritoryId() != null) {
            territoryName = territoryRepository.findById(user.getRegisteredTerritoryId())
                    .map(Territory::getTerritoryName)
                    .orElse(null);
        }

        long publicIssuesCount = issueRepository.countByUser_UserIdAndVisibility(user.getUserId(), Visibility.PUBLIC);

        return PublicUserResponse.fromEntity(user, territoryName, publicIssuesCount);
    }

    @Transactional(readOnly = true)
    public List<PublicUserResponse> searchUsers(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }

        List<User> users = userRepository.searchUsers(query.trim());
        return users.stream()
                .map(user -> {
                    String territoryName = null;
                    if (user.getRegisteredTerritoryId() != null) {
                        territoryName = territoryRepository.findById(user.getRegisteredTerritoryId())
                                .map(Territory::getTerritoryName)
                                .orElse(null);
                    }
                    long publicIssuesCount = issueRepository.countByUser_UserIdAndVisibility(user.getUserId(), Visibility.PUBLIC);
                    return PublicUserResponse.fromEntity(user, territoryName, publicIssuesCount);
                })
                .collect(Collectors.toList());
    }

    private UserProfileResponse buildUserProfileResponse(User user) {
        String territoryName = null;
        if (user.getRegisteredTerritoryId() != null) {
            territoryName = territoryRepository.findById(user.getRegisteredTerritoryId())
                    .map(Territory::getTerritoryName)
                    .orElse(null);
        }

        long reportedCount = issueRepository.countByUser_UserId(user.getUserId());
        long upvoteCount = upvoteRepository.countByUser_UserId(user.getUserId());

        return UserProfileResponse.fromEntity(user, territoryName, reportedCount, upvoteCount);
    }
}
