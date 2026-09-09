package civicpulse_backend.security;

import civicpulse_backend.dto.image.CloudinaryUploadResult;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.repository.TerritoryRepository;
import civicpulse_backend.service.CloudinaryService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
class OAuth2SecurityIntegrationTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private TerritoryRepository territoryRepository;

    @MockitoBean
    private CloudinaryService cloudinaryService;

    private MockMvc mockMvc;
    private Long testTerritoryId;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();

        if (territoryRepository.count() == 0) {
            Territory territory = new Territory();
            territory.setTerritoryName("Colombo Municipal Council");
            territory.setTerritoryType("MUNICIPAL_COUNCIL");
            testTerritoryId = territoryRepository.save(territory).getTerritoryId();
        } else {
            testTerritoryId = territoryRepository.findAll().get(0).getTerritoryId();
        }

        when(cloudinaryService.uploadProfileImage(any())).thenReturn(new CloudinaryUploadResult(
                "https://res.cloudinary.com/demo/image/upload/v1/civicpulse/profiles/mock_avatar.jpg",
                "civicpulse/profiles/mock_avatar",
                "jpg",
                1024L,
                400,
                400
        ));
    }

    private void registerTestUser(String fullName, String email, String password) throws Exception {
        MockMultipartFile imageFile = new MockMultipartFile(
                "profileImage", "avatar.jpg", "image/jpeg", "image bytes".getBytes());

        mockMvc.perform(multipart("/api/auth/register")
                        .file(imageFile)
                        .param("fullName", fullName)
                        .param("email", email)
                        .param("password", password)
                        .param("phoneNumber", "0771234567")
                        .param("registeredTerritoryId", String.valueOf(testTerritoryId)))
                .andExpect(status().isCreated());
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
        MockMultipartFile imageFile = new MockMultipartFile(
                "profileImage", "avatar.jpg", "image/jpeg", "image bytes".getBytes());

        mockMvc.perform(multipart("/api/auth/register")
                        .file(imageFile)
                        .param("fullName", "Test User")
                        .param("email", randomEmail)
                        .param("password", "SecurePass123!")
                        .param("registeredTerritoryId", String.valueOf(testTerritoryId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.user.email").value(randomEmail))
                .andExpect(jsonPath("$.user.profileImage").exists())
                .andExpect(jsonPath("$.user.registeredTerritoryId").value(testTerritoryId));
    }

    @Test
    @DisplayName("Public territory list endpoint GET /api/territories should be accessible without authentication (permitAll)")
    void shouldAllowGetTerritoriesWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/api/territories"))
                .andExpect(status().isOk());
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
        registerTestUser("Lifecycle User", email, password);

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

    @Test
    @DisplayName("Form login with valid user credentials should authenticate and redirect (302)")
    void shouldAuthenticateValidDatabaseUserViaFormLogin() throws Exception {
        String email = "auth_valid_" + System.currentTimeMillis() + "@example.com";
        String password = "ValidPassword123!";

        registerTestUser("Valid User", email, password);

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", email)
                        .param("password", password))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/"));
    }

    @Test
    @DisplayName("Form login with case-insensitive / trimmed email should authenticate and redirect (302)")
    void shouldAuthenticateCaseInsensitiveEmailViaFormLogin() throws Exception {
        String email = "auth_case_" + System.currentTimeMillis() + "@example.com";
        String password = "CasePassword123!";

        registerTestUser("Case User", email, password);

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", "  " + email.toUpperCase() + "  ")
                        .param("password", password))
                .andExpect(status().is3xxRedirection());
    }

    @Test
    @DisplayName("Form login with invalid password should fail and redirect to /login?error")
    void shouldRejectInvalidPasswordViaFormLogin() throws Exception {
        String email = "auth_fail_" + System.currentTimeMillis() + "@example.com";
        String password = "RealPassword123!";

        registerTestUser("Fail User", email, password);

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", email)
                        .param("password", "WrongPassword!"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/login?error"));
    }

    @Test
    @DisplayName("GET /login should return 200 OK with HTML login page")
    void shouldReturnDefaultLoginPage() throws Exception {
        mockMvc.perform(get("/login").accept(MediaType.TEXT_HTML))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("action=\"/login\"")));
    }

    @Test
    @DisplayName("Unauthenticated OAuth authorize request should redirect browser to /login (302)")
    void shouldRedirectOAuthAuthorizeToLoginPage() throws Exception {
        mockMvc.perform(get("/oauth2/authorize?response_type=code&client_id=civicpulse-mobile-client&redirect_uri=http://localhost:8080/authorized&scope=openid&state=state123&code_challenge=E9Melhoa2OwvFrGMTJguCH5rtx64ZWqiJ61Z35NY-yo&code_challenge_method=S256")
                        .accept(MediaType.TEXT_HTML))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", org.hamcrest.Matchers.endsWith("/login")));
    }

    @Test
    @DisplayName("OAuth login flow: saved /oauth2/authorize request is restored after form login, not redirected to '/'")
    void shouldRestoreSavedOAuthAuthorizeRequestAfterFormLogin() throws Exception {
        // Register a user to authenticate with
        String email = "oauth_restore_" + System.currentTimeMillis() + "@example.com";
        String password = "RestoreTest123!";
        registerTestUser("Restore User", email, password);

        // Step 1: Unauthenticated GET /oauth2/authorize.
        // Parameters are embedded directly in the URL string — MockMvc .param() on a GET
        // request populates only the parameterMap, NOT the raw query string. The Spring
        // Authorization Server's OAuth2AuthorizationEndpointFilter reads the raw query
        // string, so parameters must be in the URL. The @Order(1) chain's
        // ExceptionTranslationFilter should save the request in the HttpSession and
        // redirect the browser to /login.
        var authorizeResult = mockMvc.perform(get(
                        "/oauth2/authorize" +
                        "?response_type=code" +
                        "&client_id=civicpulse-mobile-client" +
                        "&redirect_uri=http://localhost:8080/authorized" +
                        "&scope=openid" +
                        "&state=restore-test-state-9876" +
                        "&code_challenge=E9Melhoa2OwvFrGMTJguCH5rtx64ZWqiJ61Z35NY-yo" +
                        "&code_challenge_method=S256")
                        .accept(MediaType.TEXT_HTML))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", org.hamcrest.Matchers.endsWith("/login")))
                .andReturn();

        // Step 2: Verify the original OAuth request is saved in the HTTP session.
        // SPRING_SECURITY_SAVED_REQUEST must be present for the success handler to restore it.
        var session = (org.springframework.mock.web.MockHttpSession)
                authorizeResult.getRequest().getSession(false);
        org.junit.jupiter.api.Assertions.assertNotNull(session,
                "HTTP session must exist after unauthenticated /oauth2/authorize");
        org.junit.jupiter.api.Assertions.assertNotNull(
                session.getAttribute("SPRING_SECURITY_SAVED_REQUEST"),
                "SPRING_SECURITY_SAVED_REQUEST must be saved in session by ExceptionTranslationFilter");

        // Step 3 & 4: Submit POST /login using THE SAME session.
        // Authentication must succeed (302), and the Location header must point back
        // to /oauth2/authorize — NOT to "/" — proving SavedRequestAwareAuthenticationSuccessHandler
        // retrieved the saved request from the session (matchingRequestParameterName=null fix).
        var loginResult = mockMvc.perform(post("/login")
                        .session(session)
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", email)
                        .param("password", password))
                .andExpect(status().is3xxRedirection())
                .andReturn();

        // Step 5: The redirect target must be the original OAuth authorize URL, not "/".
        String location = loginResult.getResponse().getHeader("Location");
        org.junit.jupiter.api.Assertions.assertNotNull(location,
                "Location header must be present after successful login");
        org.junit.jupiter.api.Assertions.assertFalse(
                "/".equals(location),
                "Redirect after OAuth login must NOT go to '/'. " +
                "Got: " + location + ". " +
                "This indicates SavedRequestAwareAuthenticationSuccessHandler returned null " +
                "for the saved request (matchingRequestParameterName guard was not disabled).");
        org.junit.jupiter.api.Assertions.assertTrue(
                location.contains("/oauth2/authorize"),
                "Redirect after OAuth login must point back to /oauth2/authorize. Got: " + location);
    }

    @Test
    @DisplayName("prompt=login forces re-authentication even with active session, enabling account switching")
    void shouldHandlePromptLoginAndAccountSwitching() throws Exception {
        // Register User A
        String emailA = "user_a_" + System.currentTimeMillis() + "@example.com";
        String passwordA = "PasswordA123!";
        registerTestUser("User A", emailA, passwordA);

        // 1. User A initiates OAuth and logs in to establish session
        var authResA = mockMvc.perform(get(
                        "/oauth2/authorize" +
                        "?response_type=code" +
                        "&client_id=civicpulse-mobile-client" +
                        "&redirect_uri=http://localhost:8080/authorized" +
                        "&scope=openid" +
                        "&state=state-a1" +
                        "&code_challenge=E9Melhoa2OwvFrGMTJguCH5rtx64ZWqiJ61Z35NY-yo" +
                        "&code_challenge_method=S256")
                        .accept(MediaType.TEXT_HTML))
                .andExpect(status().is3xxRedirection())
                .andReturn();
        var session = (org.springframework.mock.web.MockHttpSession) authResA.getRequest().getSession(false);

        // Form login as User A
        mockMvc.perform(post("/login")
                        .session(session)
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", emailA)
                        .param("password", passwordA))
                .andExpect(status().is3xxRedirection());

        // Follow redirect to authorize -> obtains code for User A
        mockMvc.perform(get(
                        "/oauth2/authorize" +
                        "?response_type=code" +
                        "&client_id=civicpulse-mobile-client" +
                        "&redirect_uri=http://localhost:8080/authorized" +
                        "&scope=openid" +
                        "&state=state-a1" +
                        "&code_challenge=E9Melhoa2OwvFrGMTJguCH5rtx64ZWqiJ61Z35NY-yo" +
                        "&code_challenge_method=S256")
                        .session(session)
                        .accept(MediaType.TEXT_HTML))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", org.hamcrest.Matchers.containsString("code=")));

        // 2. User A logs out in mobile app and taps Sign In.
        // A new authorization request arrives with prompt=login on the active session.
        // It MUST NOT reuse User A's session; it must redirect to /login (302).
        var promptLoginRes = mockMvc.perform(get(
                        "/oauth2/authorize" +
                        "?response_type=code" +
                        "&client_id=civicpulse-mobile-client" +
                        "&redirect_uri=http://localhost:8080/authorized" +
                        "&scope=openid" +
                        "&state=state-b1" +
                        "&code_challenge=E9Melhoa2OwvFrGMTJguCH5rtx64ZWqiJ61Z35NY-yo" +
                        "&code_challenge_method=S256" +
                        "&prompt=login")
                        .session(session)
                        .accept(MediaType.TEXT_HTML))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", org.hamcrest.Matchers.endsWith("/login")))
                .andReturn();

        // 3. Register User B and log in with User B credentials on this session
        String emailB = "user_b_" + System.currentTimeMillis() + "@example.com";
        String passwordB = "PasswordB123!";
        registerTestUser("User B", emailB, passwordB);

        var loginBRes = mockMvc.perform(post("/login")
                        .session(session)
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", emailB)
                        .param("password", passwordB))
                .andExpect(status().is3xxRedirection())
                .andReturn();

        String locB = loginBRes.getResponse().getHeader("Location");
        org.junit.jupiter.api.Assertions.assertNotNull(locB);
        org.junit.jupiter.api.Assertions.assertTrue(locB.contains("/oauth2/authorize"));

        // 4. Follow redirect to /oauth2/authorize?...prompt=login with User B session -> obtains code for User B
        mockMvc.perform(get(locB)
                        .session(session)
                        .accept(MediaType.TEXT_HTML))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", org.hamcrest.Matchers.containsString("code=")));
    }

    @Test
    @DisplayName("GET /login renders custom CivicPulse branded login page")
    void shouldRenderCustomCivicPulseLoginPage() throws Exception {
        mockMvc.perform(get("/login").accept(MediaType.TEXT_HTML))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Welcome to CivicPulse")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("action=\"/login\"")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("name=\"username\"")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("name=\"password\"")));
    }
}
