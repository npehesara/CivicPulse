package civicpulse_backend.security;

import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomUserDetailsServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CustomUserDetailsService userDetailsService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = new User();
        sampleUser.setUserId(1L);
        sampleUser.setEmail("citizen@example.com");
        sampleUser.setPasswordHash("$2a$10$encryptedPasswordHashString123");
        sampleUser.setFullName("John Citizen");
        sampleUser.setRole(Role.CITIZEN);
        sampleUser.setAccountStatus(AccountStatus.ACTIVE);
    }

    @Test
    @DisplayName("Should successfully load active user by exact email")
    void shouldLoadUserByExactEmail() {
        when(userRepository.findByEmail("citizen@example.com")).thenReturn(Optional.of(sampleUser));

        UserDetails userDetails = userDetailsService.loadUserByUsername("citizen@example.com");

        assertNotNull(userDetails);
        assertEquals("citizen@example.com", userDetails.getUsername());
        assertEquals("$2a$10$encryptedPasswordHashString123", userDetails.getPassword());
        assertTrue(userDetails.isEnabled());
        assertTrue(userDetails.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CITIZEN")));
    }

    @Test
    @DisplayName("Should normalize mixed-case and whitespace-padded email")
    void shouldNormalizeMixedCaseAndWhitespaceEmail() {
        when(userRepository.findByEmail("citizen@example.com")).thenReturn(Optional.of(sampleUser));

        UserDetails userDetails = userDetailsService.loadUserByUsername("  Citizen@Example.COM  ");

        assertNotNull(userDetails);
        assertEquals("citizen@example.com", userDetails.getUsername());
        verify(userRepository).findByEmail("citizen@example.com");
    }

    @Test
    @DisplayName("Should mark UserDetails as disabled if user account status is not ACTIVE")
    void shouldMarkDisabledIfAccountNotActive() {
        sampleUser.setAccountStatus(AccountStatus.SUSPENDED);
        when(userRepository.findByEmail("citizen@example.com")).thenReturn(Optional.of(sampleUser));

        UserDetails userDetails = userDetailsService.loadUserByUsername("citizen@example.com");

        assertNotNull(userDetails);
        assertFalse(userDetails.isEnabled());
    }

    @Test
    @DisplayName("Should throw UsernameNotFoundException when user is not found")
    void shouldThrowWhenUserNotFound() {
        when(userRepository.findByEmail("unknown@example.com")).thenReturn(Optional.empty());

        assertThrows(UsernameNotFoundException.class, () ->
                userDetailsService.loadUserByUsername("unknown@example.com"));
    }

    @Test
    @DisplayName("Should throw UsernameNotFoundException when email is null or empty")
    void shouldThrowWhenEmailNullOrEmpty() {
        assertThrows(UsernameNotFoundException.class, () -> userDetailsService.loadUserByUsername(null));
        assertThrows(UsernameNotFoundException.class, () -> userDetailsService.loadUserByUsername("   "));
    }
}
