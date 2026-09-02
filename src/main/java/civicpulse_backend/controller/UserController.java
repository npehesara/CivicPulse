package civicpulse_backend.controller;

import civicpulse_backend.dto.user.PublicUserResponse;
import civicpulse_backend.dto.user.UpdateProfileRequest;
import civicpulse_backend.dto.user.UserProfileResponse;
import civicpulse_backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
