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
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
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
        MockMultipartFile imageFile = new MockMultipartFile("profileImage", "avatar.jpg", "image/jpeg", "image bytes".getBytes());
        UserResponse userResponse = new UserResponse(1L, "John Doe", "john@example.com", "0771234567",
                "https://res.cloudinary.com/demo/image/upload/avatar.jpg", Role.CITIZEN, AccountStatus.ACTIVE,
                1L, "Colombo Municipal Council", LocalDateTime.now());
        AuthResponse authResponse = new AuthResponse("mockToken123", "User registered successfully", userResponse);

        when(authService.register(any(RegisterRequest.class), any())).thenReturn(authResponse);

        mockMvc.perform(multipart("/api/auth/register")
                        .file(imageFile)
                        .param("fullName", "John Doe")
                        .param("email", "john@example.com")
                        .param("password", "Password123!")
                        .param("phoneNumber", "0771234567")
                        .param("registeredTerritoryId", "1"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("mockToken123"))
                .andExpect(jsonPath("$.message").value("User registered successfully"))
                .andExpect(jsonPath("$.user.email").value("john@example.com"))
                .andExpect(jsonPath("$.user.registeredTerritoryId").value(1))
                .andExpect(jsonPath("$.user.registeredTerritoryName").value("Colombo Municipal Council"));
    }

    @Test
    void shouldReturn400WhenRegisterPayloadIsInvalid() throws Exception {
        mockMvc.perform(multipart("/api/auth/register")
                        .param("fullName", "")
                        .param("email", "invalid-email")
                        .param("password", "123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.validationErrors").exists());
    }

    @Test
    void shouldReturn409WhenRegisterDuplicateEmail() throws Exception {
        MockMultipartFile imageFile = new MockMultipartFile("profileImage", "avatar.jpg", "image/jpeg", "image bytes".getBytes());

        when(authService.register(any(RegisterRequest.class), any()))
                .thenThrow(new DuplicateEmailException("Email is already registered: john@example.com"));

        mockMvc.perform(multipart("/api/auth/register")
                        .file(imageFile)
                        .param("fullName", "John Doe")
                        .param("email", "john@example.com")
                        .param("password", "Password123!")
                        .param("phoneNumber", "0771234567")
                        .param("registeredTerritoryId", "1"))
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

    @Test
    void shouldRegisterUserWithHomeLocationAndAutoTerritory() throws Exception {
        UserResponse userResponse = new UserResponse();
        userResponse.setUserId(2L);
        userResponse.setFullName("Jane Citizen");
        userResponse.setEmail("jane@example.com");
        userResponse.setRole(Role.CITIZEN);
        userResponse.setAccountStatus(AccountStatus.ACTIVE);
        userResponse.setHomeLatitude(6.0535);
        userResponse.setHomeLongitude(80.2210);
        userResponse.setTerritoryId(7L);
        userResponse.setTerritoryName("Galle");
        userResponse.setCreatedAt(LocalDateTime.now());

        AuthResponse authResponse = new AuthResponse("tokenGalle", "User registered successfully", userResponse);
        when(authService.register(any(RegisterRequest.class), any())).thenReturn(authResponse);

        mockMvc.perform(multipart("/api/auth/register")
                        .param("fullName", "Jane Citizen")
                        .param("email", "jane@example.com")
                        .param("password", "Password123!")
                        .param("phoneNumber", "0779876543")
                        .param("homeLatitude", "6.0535")
                        .param("homeLongitude", "80.2210")
                        .param("territoryId", "7"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.homeLatitude").value(6.0535))
                .andExpect(jsonPath("$.user.homeLongitude").value(80.2210))
                .andExpect(jsonPath("$.user.territoryId").value(7))
                .andExpect(jsonPath("$.user.territoryName").value("Galle"));
    }
}
