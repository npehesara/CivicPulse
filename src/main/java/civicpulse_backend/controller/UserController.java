package civicpulse_backend.controller;

import civicpulse_backend.dto.user.ChangePasswordRequest;
import civicpulse_backend.dto.user.PublicUserResponse;
import civicpulse_backend.dto.user.UpdateProfileRequest;
import civicpulse_backend.dto.user.UserProfileResponse;
import civicpulse_backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getCurrentUserProfile() {
        UserProfileResponse response = userService.getCurrentUserProfile();
        return ResponseEntity.ok(response);
    }

    @PutMapping("/me")
    public ResponseEntity<UserProfileResponse> updateCurrentUserProfile(@Valid @RequestBody UpdateProfileRequest request) {
        UserProfileResponse response = userService.updateCurrentUserProfile(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping(value = "/me/profile-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UserProfileResponse> uploadProfileImage(
            @RequestParam(value = "profileImage", required = false) MultipartFile profileImage,
            @RequestParam(value = "file", required = false) MultipartFile file) {
        MultipartFile effectiveFile = profileImage != null && !profileImage.isEmpty() ? profileImage : file;
        if (effectiveFile == null || effectiveFile.isEmpty()) {
            throw new IllegalArgumentException("Profile image file is required");
        }
        UserProfileResponse response = userService.updateProfileImage(effectiveFile);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/me/profile-image")
    public ResponseEntity<UserProfileResponse> deleteProfileImage() {
        UserProfileResponse response = userService.deleteProfileImage();
        return ResponseEntity.ok(response);
    }

    @PutMapping("/me/password")
    public ResponseEntity<Map<String, String>> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(request);
        return ResponseEntity.ok(Map.of("message", "Password changed successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PublicUserResponse> getPublicUserProfile(@PathVariable Long id) {
        PublicUserResponse response = userService.getPublicUserProfile(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/search")
    public ResponseEntity<List<PublicUserResponse>> searchUsers(@RequestParam(required = false, defaultValue = "") String query) {
        List<PublicUserResponse> response = userService.searchUsers(query);
        return ResponseEntity.ok(response);
    }
}
