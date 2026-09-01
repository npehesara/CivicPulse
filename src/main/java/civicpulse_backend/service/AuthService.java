package civicpulse_backend.service;

import civicpulse_backend.dto.auth.AuthResponse;
import civicpulse_backend.dto.auth.LoginRequest;
import civicpulse_backend.dto.auth.RegisterRequest;
import civicpulse_backend.dto.auth.UserResponse;
import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.AccountStatusException;
import civicpulse_backend.exception.DuplicateEmailException;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new DuplicateEmailException("Email is already registered: " + normalizedEmail);
        }

        User user = new User();
        user.setFullName(request.getFullName().trim());
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setPhoneNumber(request.getPhoneNumber() != null ? request.getPhoneNumber().trim() : null);
        user.setRole(Role.CITIZEN);
        user.setAccountStatus(AccountStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());

        User savedUser = userRepository.save(user);
        String token = jwtService.generateToken(savedUser);
        UserResponse userResponse = UserResponse.fromEntity(savedUser);

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
