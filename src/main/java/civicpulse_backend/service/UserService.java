package civicpulse_backend.service;

import civicpulse_backend.dto.user.PublicUserResponse;
import civicpulse_backend.dto.user.UpdateProfileRequest;
import civicpulse_backend.dto.user.UserProfileResponse;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.entity.User;
import civicpulse_backend.entity.Visibility;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.TerritoryRepository;
import civicpulse_backend.repository.UpvoteRepository;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final TerritoryRepository territoryRepository;
    private final IssueRepository issueRepository;
    private final UpvoteRepository upvoteRepository;
    private final SecurityUtils securityUtils;

    public UserService(UserRepository userRepository,
                       TerritoryRepository territoryRepository,
                       IssueRepository issueRepository,
                       UpvoteRepository upvoteRepository,
                       SecurityUtils securityUtils) {
        this.userRepository = userRepository;
        this.territoryRepository = territoryRepository;
        this.issueRepository = issueRepository;
        this.upvoteRepository = upvoteRepository;
        this.securityUtils = securityUtils;
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

        if (request.getRegisteredTerritoryId() != null) {
            if (request.getRegisteredTerritoryId() > 0) {
                Territory territory = territoryRepository.findById(request.getRegisteredTerritoryId())
                        .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + request.getRegisteredTerritoryId()));
                currentUser.setRegisteredTerritoryId(territory.getTerritoryId());
            } else {
                currentUser.setRegisteredTerritoryId(null);
            }
        }

        User saved = userRepository.save(currentUser);
        return buildUserProfileResponse(saved);
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
