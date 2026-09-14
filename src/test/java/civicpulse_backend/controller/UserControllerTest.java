package civicpulse_backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import civicpulse_backend.dto.user.ChangePasswordRequest;
import civicpulse_backend.dto.user.UpdateProfileRequest;
import civicpulse_backend.dto.user.UserProfileResponse;
import civicpulse_backend.exception.GlobalExceptionHandler;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.service.UserService;
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

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private UserService userService;

    @InjectMocks
    private UserController userController;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        mockMvc = MockMvcBuilders.standaloneSetup(userController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void getCurrentUserProfile_ShouldReturn200() throws Exception {
        UserProfileResponse response = new UserProfileResponse();
        response.setUserId(1L);
        response.setFullName("Test User");
        response.setEmail("test@civicpulse.org");
        response.setProfileImage("https://res.cloudinary.com/test/image.jpg");

        when(userService.getCurrentUserProfile()).thenReturn(response);

        mockMvc.perform(get("/api/users/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(1L))
                .andExpect(jsonPath("$.fullName").value("Test User"))
                .andExpect(jsonPath("$.profileImage").value("https://res.cloudinary.com/test/image.jpg"));
    }

    @Test
    void updateCurrentUserProfile_ShouldReturn200() throws Exception {
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setFullName("Updated Name");
        request.setPhoneNumber("0771122334");
        request.setHomeLatitude(6.9271);
        request.setHomeLongitude(79.8612);

        UserProfileResponse response = new UserProfileResponse();
        response.setFullName("Updated Name");
        response.setPhoneNumber("0771122334");
        response.setHomeLatitude(6.9271);
        response.setHomeLongitude(79.8612);

        when(userService.updateCurrentUserProfile(any(UpdateProfileRequest.class))).thenReturn(response);

        mockMvc.perform(put("/api/users/me")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Updated Name"))
                .andExpect(jsonPath("$.homeLatitude").value(6.9271))
                .andExpect(jsonPath("$.homeLongitude").value(79.8612));
    }

    @Test
    void uploadProfileImage_ShouldReturn200() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "profileImage",
                "avatar.png",
                "image/png",
                new byte[]{1, 2, 3, 4}
        );

        UserProfileResponse response = new UserProfileResponse();
        response.setProfileImage("https://res.cloudinary.com/test/new.png");

        when(userService.updateProfileImage(any())).thenReturn(response);

        mockMvc.perform(multipart("/api/users/me/profile-image").file(file))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profileImage").value("https://res.cloudinary.com/test/new.png"));
    }

    @Test
    void deleteProfileImage_ShouldReturn200() throws Exception {
        UserProfileResponse response = new UserProfileResponse();
        response.setProfileImage(null);

        when(userService.deleteProfileImage()).thenReturn(response);

        mockMvc.perform(delete("/api/users/me/profile-image"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profileImage").doesNotExist());
    }

    @Test
    void changePassword_WithValidRequest_ShouldReturn200() throws Exception {
        ChangePasswordRequest request = new ChangePasswordRequest("OldPass123", "NewPass123", "NewPass123");

        doNothing().when(userService).changePassword(any(ChangePasswordRequest.class));

        mockMvc.perform(put("/api/users/me/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Password changed successfully"));
    }

    @Test
    void changePassword_WithInvalidCredentials_ShouldReturn401() throws Exception {
        ChangePasswordRequest request = new ChangePasswordRequest("WrongPass", "NewPass123", "NewPass123");

        doThrow(new InvalidCredentialsException("Current password is incorrect"))
                .when(userService).changePassword(any(ChangePasswordRequest.class));

        mockMvc.perform(put("/api/users/me/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void changePassword_WithShortPassword_ShouldReturn400() throws Exception {
        ChangePasswordRequest request = new ChangePasswordRequest("OldPass123", "short", "short");

        mockMvc.perform(put("/api/users/me/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }
}
