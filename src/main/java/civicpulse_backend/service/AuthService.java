package civicpulse_backend.service;

import civicpulse_backend.dto.auth.AuthResponse;
import civicpulse_backend.dto.auth.LoginRequest;
import civicpulse_backend.dto.auth.RegisterRequest;
import civicpulse_backend.dto.auth.UserResponse;
import civicpulse_backend.dto.image.CloudinaryUploadResult;
import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.AccountStatusException;
import civicpulse_backend.exception.DuplicateEmailException;
import civicpulse_backend.exception.ImageUploadException;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.TerritoryRepository;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.JwtService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final TerritoryRepository territoryRepository;
    private final CloudinaryService cloudinaryService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       TerritoryRepository territoryRepository,
                       CloudinaryService cloudinaryService,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.territoryRepository = territoryRepository;
        this.cloudinaryService = cloudinaryService;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request, MultipartFile profileImage) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new DuplicateEmailException("Email is already registered: " + normalizedEmail);
        }

        Long territoryId = request.getTerritoryId() != null ? request.getTerritoryId() : request.getRegisteredTerritoryId();
        if (territoryId == null) {
            throw new IllegalArgumentException("Territory or home location is required for registration");
        }

        Territory territory = territoryRepository.findById(territoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + territoryId));

        CloudinaryUploadResult uploadResult = null;
        if (profileImage != null && !profileImage.isEmpty()) {
            // Upload profile image to Cloudinary (validates MIME type and enforces <= 5MB)
            uploadResult = cloudinaryService.uploadProfileImage(profileImage);
        }

        User user = new User();
        user.setFullName(request.getFullName().trim());
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setPhoneNumber(request.getPhoneNumber() != null && !request.getPhoneNumber().isBlank()
                ? request.getPhoneNumber().trim() : null);
        user.setRole(Role.CITIZEN);
        user.setAccountStatus(AccountStatus.ACTIVE);
        user.setProfileImage(uploadResult != null ? uploadResult.secureUrl() : null);
        user.setHomeLatitude(request.getHomeLatitude());
        user.setHomeLongitude(request.getHomeLongitude());
        user.setTerritoryId(territory.getTerritoryId());
        user.setCreatedAt(LocalDateTime.now());

        User savedUser;
        try {
            savedUser = userRepository.save(user);
        } catch (Exception ex) {
            if (uploadResult != null) {
                log.error("Failed to save user in database after Cloudinary upload. Cleaning up image: {}", uploadResult.publicId(), ex);
                try {
                    cloudinaryService.deleteImage(uploadResult.publicId());
                } catch (Exception cleanupEx) {
                    log.error("Failed to delete orphaned Cloudinary image [{}]: {}", uploadResult.publicId(), cleanupEx.getMessage(), cleanupEx);
                }
            }
            throw ex;
        }

        String token = jwtService.generateToken(savedUser);
        UserResponse userResponse = UserResponse.fromEntity(savedUser, territory.getTerritoryName());

        return new AuthResponse(token, "User registered successfully", userResponse);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        if (user.getAccountStatus() != AccountStatus.ACTIVE) {
            throw new AccountStatusException("Account is " + user.getAccountStatus().name().toLowerCase() + ". Please contact support.");
        }

        String token = jwtService.generateToken(user);
        UserResponse userResponse = UserResponse.fromEntity(user);

        return new AuthResponse(token, "Login successful", userResponse);
    }
}
