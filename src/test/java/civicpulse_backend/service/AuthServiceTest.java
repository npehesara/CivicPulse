package civicpulse_backend.service;

import civicpulse_backend.dto.auth.AuthResponse;
import civicpulse_backend.dto.auth.LoginRequest;
import civicpulse_backend.dto.auth.RegisterRequest;
import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.AccountStatusException;
import civicpulse_backend.exception.DuplicateEmailException;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, passwordEncoder, jwtService);
    }

    @Test
    void shouldRegisterUserSuccessfully() {
        RegisterRequest request = new RegisterRequest("John Doe", "john@example.com", "Password123!", "0771234567");

        when(userRepository.existsByEmail("john@example.com")).thenReturn(false);
        when(passwordEncoder.encode("Password123!")).thenReturn("encodedPasswordHash");

        User savedUser = new User();
        savedUser.setUserId(1L);
        savedUser.setFullName("John Doe");
        savedUser.setEmail("john@example.com");
        savedUser.setPasswordHash("encodedPasswordHash");
        savedUser.setPhoneNumber("0771234567");
        savedUser.setRole(Role.CITIZEN);
        savedUser.setAccountStatus(AccountStatus.ACTIVE);
        savedUser.setCreatedAt(LocalDateTime.now());

        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(jwtService.generateToken(savedUser)).thenReturn("dummyJwtToken");

        AuthResponse response = authService.register(request);

        assertNotNull(response);
        assertEquals("dummyJwtToken", response.getToken());
        assertEquals("User registered successfully", response.getMessage());
        assertNotNull(response.getUser());
        assertEquals("john@example.com", response.getUser().getEmail());
        assertEquals(Role.CITIZEN, response.getUser().getRole());
        assertEquals(AccountStatus.ACTIVE, response.getUser().getAccountStatus());

        verify(passwordEncoder).encode("Password123!");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void shouldThrowExceptionWhenRegisteringDuplicateEmail() {
        RegisterRequest request = new RegisterRequest("John Doe", "john@example.com", "Password123!", "0771234567");

        when(userRepository.existsByEmail("john@example.com")).thenReturn(true);

        DuplicateEmailException exception = assertThrows(
                DuplicateEmailException.class,
                () -> authService.register(request)
        );

        assertTrue(exception.getMessage().contains("Email is already registered"));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void shouldLoginSuccessfullyWithValidCredentials() {
        LoginRequest request = new LoginRequest("john@example.com", "Password123!");

        User existingUser = new User();
        existingUser.setUserId(1L);
        existingUser.setFullName("John Doe");
        existingUser.setEmail("john@example.com");
        existingUser.setPasswordHash("encodedPasswordHash");
        existingUser.setRole(Role.CITIZEN);
        existingUser.setAccountStatus(AccountStatus.ACTIVE);
        existingUser.setCreatedAt(LocalDateTime.now());

        when(userRepository.findByEmail("john@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("Password123!", "encodedPasswordHash")).thenReturn(true);
        when(jwtService.generateToken(existingUser)).thenReturn("dummyJwtToken");

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertEquals("dummyJwtToken", response.getToken());
        assertEquals("Login successful", response.getMessage());
        assertEquals("john@example.com", response.getUser().getEmail());
    }

    @Test
    void shouldThrowExceptionWhenLoginWithNonExistentEmail() {
        LoginRequest request = new LoginRequest("nonexistent@example.com", "Password123!");

        when(userRepository.findByEmail("nonexistent@example.com")).thenReturn(Optional.empty());

        InvalidCredentialsException exception = assertThrows(
                InvalidCredentialsException.class,
                () -> authService.login(request)
        );

        assertEquals("Invalid email or password", exception.getMessage());
    }

    @Test
    void shouldThrowExceptionWhenLoginWithInvalidPassword() {
        LoginRequest request = new LoginRequest("john@example.com", "WrongPassword");

        User existingUser = new User();
        existingUser.setEmail("john@example.com");
        existingUser.setPasswordHash("encodedPasswordHash");

        when(userRepository.findByEmail("john@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("WrongPassword", "encodedPasswordHash")).thenReturn(false);

        InvalidCredentialsException exception = assertThrows(
                InvalidCredentialsException.class,
                () -> authService.login(request)
        );

        assertEquals("Invalid email or password", exception.getMessage());
    }

    @Test
    void shouldThrowExceptionWhenLoginWithInactiveAccount() {
        LoginRequest request = new LoginRequest("john@example.com", "Password123!");

        User inactiveUser = new User();
        inactiveUser.setEmail("john@example.com");
        inactiveUser.setPasswordHash("encodedPasswordHash");
        inactiveUser.setAccountStatus(AccountStatus.SUSPENDED);

        when(userRepository.findByEmail("john@example.com")).thenReturn(Optional.of(inactiveUser));
        when(passwordEncoder.matches("Password123!", "encodedPasswordHash")).thenReturn(true);

        AccountStatusException exception = assertThrows(
                AccountStatusException.class,
                () -> authService.login(request)
        );

        assertTrue(exception.getMessage().contains("suspended"));
    }
}
