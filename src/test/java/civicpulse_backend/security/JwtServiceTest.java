package civicpulse_backend.security;

import civicpulse_backend.config.JwtProperties;
import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;

class JwtServiceTest {

    private JwtService jwtService;
    private JwtProperties jwtProperties;

    @BeforeEach
    void setUp() {
        jwtProperties = new JwtProperties();
        jwtProperties.setSecret("404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970");
        jwtProperties.setExpiration(3600000); // 1 hour
        jwtService = new JwtService(jwtProperties);
    }

    @Test
    void shouldGenerateAndValidateTokenSuccessfully() {
        User user = new User();
        user.setUserId(1L);
        user.setFullName("John Doe");
        user.setEmail("john@example.com");
        user.setRole(Role.CITIZEN);
        user.setAccountStatus(AccountStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());

        String token = jwtService.generateToken(user);
        assertNotNull(token);
        assertFalse(token.isEmpty());

        String extractedEmail = jwtService.extractUsername(token);
        assertEquals("john@example.com", extractedEmail);

        UserDetails userDetails = new org.springframework.security.core.userdetails.User(
                "john@example.com",
                "passwordHash",
                Collections.emptyList()
        );

        assertTrue(jwtService.isTokenValid(token, userDetails));
        assertFalse(jwtService.isTokenExpired(token));
    }

    @Test
    void shouldExtractClaimsCorrectly() {
        User user = new User();
        user.setUserId(42L);
        user.setFullName("Alice Smith");
        user.setEmail("alice@example.com");
        user.setRole(Role.ADMIN);
        user.setAccountStatus(AccountStatus.ACTIVE);

        String token = jwtService.generateToken(user);
        var claims = jwtService.extractAllClaims(token);

        assertEquals("alice@example.com", claims.getSubject());
        assertEquals("ADMIN", claims.get("role"));
        assertEquals("Alice Smith", claims.get("fullName"));
        assertEquals(42, ((Number) claims.get("userId")).longValue());
    }
}
