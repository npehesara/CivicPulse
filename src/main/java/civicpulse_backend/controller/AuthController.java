package civicpulse_backend.controller;

import civicpulse_backend.dto.auth.AuthResponse;
import civicpulse_backend.dto.auth.LoginRequest;
import civicpulse_backend.dto.auth.RegisterRequest;
import civicpulse_backend.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping(value = "/register", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AuthResponse> register(
            @Valid @ModelAttribute RegisterRequest request,
            @RequestParam(value = "profileImage", required = false) MultipartFile profileImage) {
        AuthResponse response = authService.register(request, profileImage);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }
}
