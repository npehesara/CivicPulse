package civicpulse_backend.service;

import civicpulse_backend.dto.image.CloudinaryUploadResult;
import civicpulse_backend.dto.user.ChangePasswordRequest;
import civicpulse_backend.dto.user.UpdateProfileRequest;
import civicpulse_backend.dto.user.UserProfileResponse;
import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.TerritoryRepository;
import civicpulse_backend.repository.UpvoteRepository;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private TerritoryRepository territoryRepository;

    @Mock
    private IssueRepository issueRepository;

    @Mock
    private UpvoteRepository upvoteRepository;

    @Mock
    private SecurityUtils securityUtils;

    @Mock
    private CloudinaryService cloudinaryService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    private User testUser;
    private Territory testTerritory;

    @BeforeEach
    void setUp() {
        testTerritory = new Territory("Colombo", "DISTRICT", null, null);
        testTerritory.setTerritoryId(1L);

        testUser = new User();
        testUser.setUserId(10L);
        testUser.setFullName("Kasun Perera");
        testUser.setEmail("kasun@example.com");
        testUser.setPasswordHash("$2a$10$hashedPasswordHere");
        testUser.setPhoneNumber("0771234567");
        testUser.setRole(Role.CITIZEN);
        testUser.setAccountStatus(AccountStatus.ACTIVE);
        testUser.setTerritoryId(1L);
        testUser.setHomeLatitude(6.9271);
        testUser.setHomeLongitude(79.8612);
        testUser.setProfileImage("https://res.cloudinary.com/test/image/upload/v1/civicpulse/profiles/old_pic.jpg");
        testUser.setCreatedAt(LocalDateTime.now());
    }

    @Test
    void getCurrentUserProfile_ShouldReturnPopulatedProfile() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(territoryRepository.findById(1L)).thenReturn(Optional.of(testTerritory));
        when(issueRepository.countByUser_UserId(10L)).thenReturn(5L);
        when(upvoteRepository.countByUser_UserId(10L)).thenReturn(12L);

        UserProfileResponse response = userService.getCurrentUserProfile();

        assertNotNull(response);
        assertEquals(10L, response.getUserId());
        assertEquals("Kasun Perera", response.getFullName());
        assertEquals("kasun@example.com", response.getEmail());
        assertEquals("0771234567", response.getPhoneNumber());
        assertEquals("https://res.cloudinary.com/test/image/upload/v1/civicpulse/profiles/old_pic.jpg", response.getProfileImage());
        assertEquals(6.9271, response.getHomeLatitude());
        assertEquals(79.8612, response.getHomeLongitude());
        assertEquals("Colombo", response.getTerritoryName());
        assertEquals(5L, response.getReportedIssuesCount());
        assertEquals(12L, response.getUpvotesGivenCount());
    }

    @Test
    void updateCurrentUserProfile_ShouldUpdateAllowedFields() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(territoryRepository.findById(1L)).thenReturn(Optional.of(testTerritory));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setFullName("Kasun Updated");
        request.setPhoneNumber("0779998888");
        request.setHomeLatitude(6.9300);
        request.setHomeLongitude(79.8600);
        request.setTerritoryId(1L);

        UserProfileResponse response = userService.updateCurrentUserProfile(request);

        assertNotNull(response);
        assertEquals("Kasun Updated", response.getFullName());
        assertEquals("0779998888", response.getPhoneNumber());
        assertEquals(6.9300, response.getHomeLatitude());
        assertEquals(79.8600, response.getHomeLongitude());
        verify(userRepository).save(testUser);
    }

    @Test
    void updateCurrentUserProfile_WithInvalidTerritory_ShouldThrowException() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(territoryRepository.findById(99L)).thenReturn(Optional.empty());

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setTerritoryId(99L);

        assertThrows(ResourceNotFoundException.class, () -> userService.updateCurrentUserProfile(request));
        verify(userRepository, never()).save(any());
    }

    @Test
    void updateProfileImage_ShouldUploadToCloudinaryAndDeleteOldAsset() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        MockMultipartFile newImage = new MockMultipartFile("profileImage", "new_pic.jpg", "image/jpeg", new byte[]{1, 2, 3});
        CloudinaryUploadResult uploadResult = new CloudinaryUploadResult(
                "https://res.cloudinary.com/test/image/upload/v2/civicpulse/profiles/new_pic.jpg",
                "civicpulse/profiles/new_pic",
                "jpg",
                3L,
                100,
                100
        );
        when(cloudinaryService.uploadProfileImage(newImage)).thenReturn(uploadResult);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(cloudinaryService.deleteImage("civicpulse/profiles/old_pic")).thenReturn(true);

        UserProfileResponse response = userService.updateProfileImage(newImage);

        assertNotNull(response);
        assertEquals("https://res.cloudinary.com/test/image/upload/v2/civicpulse/profiles/new_pic.jpg", response.getProfileImage());
        verify(cloudinaryService).uploadProfileImage(newImage);
        verify(cloudinaryService).deleteImage("civicpulse/profiles/old_pic");
        verify(userRepository).save(testUser);
    }

    @Test
    void deleteProfileImage_ShouldClearImageAndDeleteCloudinaryAsset() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(cloudinaryService.deleteImage("civicpulse/profiles/old_pic")).thenReturn(true);

        UserProfileResponse response = userService.deleteProfileImage();

        assertNotNull(response);
        assertNull(response.getProfileImage());
        verify(cloudinaryService).deleteImage("civicpulse/profiles/old_pic");
        verify(userRepository).save(testUser);
    }

    @Test
    void changePassword_WithCorrectCurrentPassword_ShouldSucceed() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(passwordEncoder.matches("OldPassword123", "$2a$10$hashedPasswordHere")).thenReturn(true);
        when(passwordEncoder.matches("NewPassword456", "$2a$10$hashedPasswordHere")).thenReturn(false);
        when(passwordEncoder.encode("NewPassword456")).thenReturn("$2a$10$newHashedPassword");

        ChangePasswordRequest request = new ChangePasswordRequest("OldPassword123", "NewPassword456", "NewPassword456");

        assertDoesNotThrow(() -> userService.changePassword(request));
        verify(passwordEncoder).encode("NewPassword456");
        verify(userRepository).save(testUser);
        assertEquals("$2a$10$newHashedPassword", testUser.getPasswordHash());
    }

    @Test
    void changePassword_WithIncorrectCurrentPassword_ShouldThrowInvalidCredentials() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(passwordEncoder.matches("WrongPassword", "$2a$10$hashedPasswordHere")).thenReturn(false);

        ChangePasswordRequest request = new ChangePasswordRequest("WrongPassword", "NewPassword456", "NewPassword456");

        assertThrows(InvalidCredentialsException.class, () -> userService.changePassword(request));
        verify(userRepository, never()).save(any());
    }

    @Test
    void changePassword_WithMismatchedConfirmPassword_ShouldThrowIllegalArgument() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(passwordEncoder.matches("OldPassword123", "$2a$10$hashedPasswordHere")).thenReturn(true);

        ChangePasswordRequest request = new ChangePasswordRequest("OldPassword123", "NewPassword456", "DifferentPassword");

        assertThrows(IllegalArgumentException.class, () -> userService.changePassword(request));
        verify(userRepository, never()).save(any());
    }

    @Test
    void changePassword_WithSameNewPassword_ShouldThrowIllegalArgument() {
        when(securityUtils.getCurrentUser()).thenReturn(testUser);
        when(passwordEncoder.matches("OldPassword123", "$2a$10$hashedPasswordHere")).thenReturn(true);

        ChangePasswordRequest request = new ChangePasswordRequest("OldPassword123", "OldPassword123", "OldPassword123");

        assertThrows(IllegalArgumentException.class, () -> userService.changePassword(request));
        verify(userRepository, never()).save(any());
    }
}
