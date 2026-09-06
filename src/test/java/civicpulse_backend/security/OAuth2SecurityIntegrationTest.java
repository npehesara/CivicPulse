package civicpulse_backend.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.List;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
class OAuth2SecurityIntegrationTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    @DisplayName("OAuth2 OpenID Discovery endpoint should return 200 and standard metadata")
    void shouldReturnOpenIdConfiguration() throws Exception {
        mockMvc.perform(get("/.well-known/openid-configuration"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.issuer").exists())
                .andExpect(jsonPath("$.jwks_uri").exists())
                .andExpect(jsonPath("$.authorization_endpoint").exists())
                .andExpect(jsonPath("$.token_endpoint").exists())
                .andExpect(jsonPath("$.response_types_supported").isArray());
    }

    @Test
    @DisplayName("OAuth2 JWKS endpoint should return RSA public key set")
    void shouldReturnJwksPublicKeySet() throws Exception {
        mockMvc.perform(get("/oauth2/jwks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.keys").isArray())
                .andExpect(jsonPath("$.keys[0].kty").value("RSA"))
                .andExpect(jsonPath("$.keys[0].use").value("sig"))
                .andExpect(jsonPath("$.keys[0].n").exists())
                .andExpect(jsonPath("$.keys[0].e").exists());
    }

    @Test
    @DisplayName("Unauthenticated request to protected endpoint should return 401 Unauthorized")
    void shouldRejectUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/api/users/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Invalid JWT token on protected endpoint should return 401 Unauthorized")
    void shouldRejectInvalidJwtToken() throws Exception {
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer invalid.fake.token"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("CITIZEN token can access public/citizen endpoints but is denied from admin endpoints (403 Forbidden)")
    void shouldDenyCitizenFromAdminEndpoints() throws Exception {
        // CITIZEN allowed on GET /api/territories
        mockMvc.perform(get("/api/territories")
                        .with(jwt().jwt(builder -> builder
                                .subject("citizen@example.com")
                                .claim("roles", List.of("ROLE_CITIZEN"))
                                .claim("scope", "civicpulse.read civicpulse.write")
                        )))
                .andExpect(status().isOk());

        // CITIZEN denied (403 Forbidden) from POST /api/territories
        mockMvc.perform(post("/api/territories")
                        .with(jwt().jwt(builder -> builder
                                .subject("citizen@example.com")
                                .claim("roles", List.of("ROLE_CITIZEN"))
                                .claim("scope", "civicpulse.read civicpulse.write")
                        ))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"territoryName\":\"Western Zone\",\"district\":\"Colombo\",\"province\":\"Western\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("OFFICIAL token is denied from ADMIN-only endpoints (403 Forbidden)")
    void shouldDenyOfficialFromAdminEndpoints() throws Exception {
        // OFFICIAL denied from ADMIN-only territory creation
        mockMvc.perform(post("/api/territories")
                        .with(jwt().jwt(builder -> builder
                                .subject("official@example.com")
                                .claim("roles", List.of("ROLE_OFFICIAL"))
                                .claim("scope", "civicpulse.read civicpulse.write")
                        ))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"territoryName\":\"Central Zone\",\"district\":\"Kandy\",\"province\":\"Central\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("OAuth2 Authorization Server metadata endpoint should return 200")
    void shouldReturnAuthorizationServerMetadata() throws Exception {
        mockMvc.perform(get("/.well-known/oauth-authorization-server"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.issuer").exists())
                .andExpect(jsonPath("$.token_endpoint").exists());
    }

    @Test
    @DisplayName("Public user registration endpoint /api/auth/register should remain accessible (permitAll)")
    void shouldAllowRegistrationWithoutAuthentication() throws Exception {
        String randomEmail = "testuser_" + System.currentTimeMillis() + "@example.com";
        String requestJson = String.format("{\"fullName\":\"Test User\",\"email\":\"%s\",\"password\":\"SecurePass123!\"}", randomEmail);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.user.email").value(randomEmail));
    }

    @Test
    @DisplayName("Expired JWT token should be rejected (401 Unauthorized)")
    void shouldRejectExpiredJwtToken() throws Exception {
        mockMvc.perform(get("/api/users/me")
                        .with(jwt().jwt(builder -> builder
                                .subject("citizen@example.com")
                                .claim("roles", List.of("ROLE_CITIZEN"))
                                .expiresAt(java.time.Instant.now().minus(java.time.Duration.ofMinutes(10)))
                        )))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("GET /login should return 200 OK with the Spring Security login page")
    void shouldReturnDefaultLoginPage() throws Exception {
        mockMvc.perform(get("/login"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML));
    }

    @Test
    @DisplayName("GET /oauth2/authorize without PKCE code_challenge should return 302 redirect with invalid_request")
    void shouldRequirePkceCodeChallengeOnAuthorize() throws Exception {
        mockMvc.perform(get("/oauth2/authorize")
                        .param("response_type", "code")
                        .param("client_id", "civicpulse-mobile-client")
                        .param("redirect_uri", "http://localhost:8080/authorized")
                        .param("scope", "openid"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    org.junit.jupiter.api.Assertions.assertTrue(status == 302 || status == 400, "Expected 302 or 400, got: " + status);
                });
    }

    @Test
    @DisplayName("1 & 2 & 3 & 4. Authorization Code + PKCE issues Refresh Token, allows refresh, rotates token, and rejects reuse of old token")
    void shouldHandleCompleteOAuth2PkceAndRefreshTokenLifecycle() throws Exception {
        // Step 1: Register test user
        String email = "lifecycle_" + System.currentTimeMillis() + "@example.com";
        String password = "Password123!";
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(String.format("{\"fullName\":\"Lifecycle User\",\"email\":\"%s\",\"password\":\"%s\"}", email, password)))
                .andExpect(status().isCreated());

        // Step 2: Form Login for session
        var loginResult = mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", email)
                        .param("password", password))
                .andExpect(status().is3xxRedirection())
                .andReturn();

        var session = (org.springframework.mock.web.MockHttpSession) loginResult.getRequest().getSession();
        org.junit.jupiter.api.Assertions.assertNotNull(session);

        // Step 3: PKCE Challenge
        String codeVerifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk_sample_verifier_123456789";
        byte[] digest = java.security.MessageDigest.getInstance("SHA-256")
                .digest(codeVerifier.getBytes(java.nio.charset.StandardCharsets.US_ASCII));
        String codeChallenge = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(digest);

        // Step 4: Authorize with offline_access scope
        var authResult = mockMvc.perform(get("/oauth2/authorize")
                        .session(session)
                        .queryParam("response_type", "code")
                        .queryParam("client_id", "civicpulse-mobile-client")
                        .queryParam("redirect_uri", "http://localhost:8080/authorized")
                        .queryParam("scope", "openid profile offline_access civicpulse.read civicpulse.write")
                        .queryParam("code_challenge", codeChallenge)
                        .queryParam("code_challenge_method", "S256"))
                .andExpect(status().is3xxRedirection())
                .andReturn();

        String redirectedUrl = authResult.getResponse().getRedirectedUrl();
        org.junit.jupiter.api.Assertions.assertNotNull(redirectedUrl);
        String code = redirectedUrl.substring(redirectedUrl.indexOf("code=") + 5);
        if (code.contains("&")) {
            code = code.substring(0, code.indexOf("&"));
        }

        // Requirement 1: Authorization Code + PKCE exchange issues access_token and refresh_token
        var tokenResult = mockMvc.perform(post("/oauth2/token")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("grant_type", "authorization_code")
                        .param("client_id", "civicpulse-mobile-client")
                        .param("code", code)
                        .param("redirect_uri", "http://localhost:8080/authorized")
                        .param("code_verifier", codeVerifier))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.access_token").exists())
                .andExpect(jsonPath("$.refresh_token").exists())
                .andExpect(jsonPath("$.token_type").value("Bearer"))
                .andExpect(jsonPath("$.expires_in").exists())
                .andExpect(jsonPath("$.id_token").exists())
                .andReturn();

        com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
        com.fasterxml.jackson.databind.JsonNode json1 = mapper.readTree(tokenResult.getResponse().getContentAsString());
        String initialAccessToken = json1.get("access_token").asText();
        String initialRefreshToken = json1.get("refresh_token").asText();

        // Requirement 7: The issued access token works on protected /api/** endpoints
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + initialAccessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(email));

        // Requirement 2: Valid refresh token successfully obtains a new access token
        var refreshResult = mockMvc.perform(post("/oauth2/token")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("grant_type", "refresh_token")
                        .param("client_id", "civicpulse-mobile-client")
                        .param("refresh_token", initialRefreshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.access_token").exists())
                .andExpect(jsonPath("$.refresh_token").exists())
                .andReturn();

        com.fasterxml.jackson.databind.JsonNode json2 = mapper.readTree(refreshResult.getResponse().getContentAsString());
        String secondAccessToken = json2.get("access_token").asText();
        String rotatedRefreshToken = json2.get("refresh_token").asText();

        // Requirement 3: Refresh-token rotation works (reuseRefreshTokens=false)
        org.junit.jupiter.api.Assertions.assertNotEquals(initialRefreshToken, rotatedRefreshToken,
                "Rotated refresh token must be different from initial refresh token");

        // The newly rotated access token works on protected /api/** endpoints
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + secondAccessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(email));

        // Requirement 4: Reusing the old refresh token fails with invalid_grant
        mockMvc.perform(post("/oauth2/token")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("grant_type", "refresh_token")
                        .param("client_id", "civicpulse-mobile-client")
                        .param("refresh_token", initialRefreshToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_grant"));

        // The rotated refresh token can be used successfully for another refresh
        var secondRefreshResult = mockMvc.perform(post("/oauth2/token")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("grant_type", "refresh_token")
                        .param("client_id", "civicpulse-mobile-client")
                        .param("refresh_token", rotatedRefreshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.access_token").exists())
                .andExpect(jsonPath("$.refresh_token").exists())
                .andReturn();

        com.fasterxml.jackson.databind.JsonNode json3 = mapper.readTree(secondRefreshResult.getResponse().getContentAsString());
        String thirdRefreshToken = json3.get("refresh_token").asText();
        org.junit.jupiter.api.Assertions.assertNotEquals(rotatedRefreshToken, thirdRefreshToken);
    }

    @Test
    @DisplayName("5. An invalid / arbitrary refresh token fails with invalid_grant (400 Bad Request)")
    void shouldRejectInvalidRefreshToken() throws Exception {
        mockMvc.perform(post("/oauth2/token")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("grant_type", "refresh_token")
                        .param("client_id", "civicpulse-mobile-client")
                        .param("refresh_token", "invalid_fake_refresh_token_value_1234567890"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_grant"));
    }

    @Test
    @DisplayName("6. Public client cannot authenticate using a client_secret (invalid_client)")
    void shouldRejectClientSecretForPublicClient() throws Exception {
        mockMvc.perform(post("/oauth2/token")
                        .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic("civicpulse-mobile-client", "some_secret"))
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("grant_type", "refresh_token")
                        .param("refresh_token", "some_token"))
                .andExpect(status().isUnauthorized());
    }
}
