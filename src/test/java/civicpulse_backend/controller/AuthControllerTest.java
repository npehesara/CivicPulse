package civicpulse_backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import civicpulse_backend.dto.auth.AuthResponse;
import civicpulse_backend.dto.auth.LoginRequest;
import civicpulse_backend.dto.auth.RegisterRequest;
import civicpulse_backend.dto.auth.UserResponse;
import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.exception.DuplicateEmailException;
import civicpulse_backend.exception.GlobalExceptionHandler;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private AuthService authService;

    @InjectMocks
    private AuthController authController;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        mockMvc = MockMvcBuilders.standaloneSetup(authController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void shouldRegisterUserSuccessfullyAndReturn201() throws Exception {
        RegisterRequest request = new RegisterRequest("John Doe", "john@example.com", "Password123!", "0771234567");
        UserResponse userResponse = new UserResponse(1L, "John Doe", "john@example.com", "0771234567", null, Role.CITIZEN, AccountStatus.ACTIVE, LocalDateTime.now());
        AuthResponse authResponse = new AuthResponse("mockToken123", "User registered successfully", userResponse);

        when(authService.register(any(RegisterRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("mockToken123"))
                .andExpect(jsonPath("$.message").value("User registered successfully"))
                .andExpect(jsonPath("$.user.email").value("john@example.com"));
    }

    @Test
    void shouldReturn400WhenRegisterPayloadIsInvalid() throws Exception {
        RegisterRequest request = new RegisterRequest("", "invalid-email", "123", null);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.validationErrors").exists());
    }

    @Test
    void shouldReturn409WhenRegisterDuplicateEmail() throws Exception {
        RegisterRequest request = new RegisterRequest("John Doe", "john@example.com", "Password123!", "0771234567");

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new DuplicateEmailException("Email is already registered: john@example.com"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message").value("Email is already registered: john@example.com"));
    }

    @Test
    void shouldLoginSuccessfullyAndReturn200() throws Exception {
        LoginRequest request = new LoginRequest("john@example.com", "Password123!");
        UserResponse userResponse = new UserResponse(1L, "John Doe", "john@example.com", "0771234567", null, Role.CITIZEN, AccountStatus.ACTIVE, LocalDateTime.now());
        AuthResponse authResponse = new AuthResponse("mockToken123", "Login successful", userResponse);

        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("mockToken123"))
                .andExpect(jsonPath("$.message").value("Login successful"))
                .andExpect(jsonPath("$.user.email").value("john@example.com"));
    }

    @Test
    void shouldReturn401WhenInvalidCredentialsOnLogin() throws Exception {
        LoginRequest request = new LoginRequest("john@example.com", "WrongPassword");

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new InvalidCredentialsException("Invalid email or password"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }
}
