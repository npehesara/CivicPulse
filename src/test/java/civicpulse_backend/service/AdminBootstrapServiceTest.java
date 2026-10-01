package civicpulse_backend.service;

import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminBootstrapServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Captor
    private ArgumentCaptor<User> userCaptor;

    private AdminBootstrapService adminBootstrapService;

    @BeforeEach
    void setUp() {
        adminBootstrapService = new AdminBootstrapService(userRepository, passwordEncoder);
    }

    @Test
    void shouldSkipIfEmailMissing() {
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapEmail", null);
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapPassword", "password");

        adminBootstrapService.run();

        verify(userRepository, never()).findByEmail(anyString());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void shouldSkipIfPasswordMissing() {
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapEmail", "admin@example.com");
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapPassword", "");

        adminBootstrapService.run();

        verify(userRepository, never()).findByEmail(anyString());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void shouldSkipIfAdminExists() {
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapEmail", "admin@example.com");
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapPassword", "password");

        User existingAdmin = new User();
        existingAdmin.setEmail("admin@example.com");
        existingAdmin.setRole(Role.ADMIN);

        when(userRepository.findByEmail("admin@example.com")).thenReturn(Optional.of(existingAdmin));

        adminBootstrapService.run();

        verify(userRepository, times(1)).findByEmail("admin@example.com");
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void shouldNotPromoteExistingCitizen() {
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapEmail", "citizen@example.com");
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapPassword", "password");

        User existingCitizen = new User();
        existingCitizen.setEmail("citizen@example.com");
        existingCitizen.setRole(Role.CITIZEN);

        when(userRepository.findByEmail("citizen@example.com")).thenReturn(Optional.of(existingCitizen));

        adminBootstrapService.run();

        verify(userRepository, times(1)).findByEmail("citizen@example.com");
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void shouldCreateAdminIfNotExist() {
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapEmail", "admin@example.com");
        ReflectionTestUtils.setField(adminBootstrapService, "bootstrapPassword", "securePassword123");

        when(userRepository.findByEmail("admin@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("securePassword123")).thenReturn("hashedPassword");

        adminBootstrapService.run();

        verify(userRepository, times(1)).findByEmail("admin@example.com");
        verify(userRepository, times(1)).save(userCaptor.capture());

        User savedUser = userCaptor.getValue();
        assertEquals("admin@example.com", savedUser.getEmail());
        assertEquals("System Administrator", savedUser.getFullName());
        assertEquals("hashedPassword", savedUser.getPasswordHash());
        assertEquals(Role.ADMIN, savedUser.getRole());
        assertEquals(AccountStatus.ACTIVE, savedUser.getAccountStatus());
    }
}
