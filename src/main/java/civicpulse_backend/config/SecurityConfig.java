package civicpulse_backend.config;

import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.JwtAuthenticationEntryPoint;
import civicpulse_backend.security.JwtAuthenticationFilter;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.core.oidc.OidcScopes;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.authorization.OAuth2TokenType;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.config.annotation.web.configuration.OAuth2AuthorizationServerConfiguration;
import org.springframework.security.config.annotation.web.configurers.oauth2.server.authorization.OAuth2AuthorizationServerConfigurer;
import org.springframework.security.oauth2.server.authorization.settings.AuthorizationServerSettings;
import org.springframework.security.oauth2.server.authorization.settings.ClientSettings;
import org.springframework.security.oauth2.server.authorization.settings.TokenSettings;
import org.springframework.security.oauth2.server.authorization.token.JwtEncodingContext;
import org.springframework.security.oauth2.server.authorization.token.OAuth2TokenCustomizer;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.util.matcher.MediaTypeRequestMatcher;
import org.springframework.security.web.savedrequest.HttpSessionRequestCache;
import org.springframework.security.web.savedrequest.RequestCache;
import org.springframework.web.filter.ForwardedHeaderFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.security.crypto.keygen.Base64StringKeyGenerator;
import org.springframework.security.crypto.keygen.StringKeyGenerator;
import org.springframework.security.oauth2.core.OAuth2RefreshToken;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.authorization.token.DelegatingOAuth2TokenGenerator;
import org.springframework.security.oauth2.server.authorization.token.JwtGenerator;
import org.springframework.security.oauth2.server.authorization.token.OAuth2AccessTokenGenerator;
import org.springframework.security.oauth2.server.authorization.token.OAuth2TokenGenerator;
import civicpulse_backend.security.PublicClientRefreshTokenAuthenticationConverter;
import civicpulse_backend.security.PublicClientRefreshTokenAuthenticationProvider;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    private final UserDetailsService userDetailsService;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter,
            JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint,
            UserDetailsService userDetailsService) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.jwtAuthenticationEntryPoint = jwtAuthenticationEntryPoint;
        this.userDetailsService = userDetailsService;
    }

    @Bean
    public ForwardedHeaderFilter forwardedHeaderFilter() {
        return new ForwardedHeaderFilter();
    }

    @Bean
    public RequestCache requestCache() {
        HttpSessionRequestCache cache = new HttpSessionRequestCache();
        // Spring Security 6+ defaults matchingRequestParameterName to "continue",
        // meaning getRequest() returns null unless ?continue is present in the URL.
        // LoginUrlAuthenticationEntryPoint does NOT append ?continue, so POST /login
        // never carries it. Setting null restores the pre-6 behaviour: always check
        // the session, allowing SavedRequestAwareAuthenticationSuccessHandler to
        // retrieve the saved OAuth /oauth2/authorize request and redirect correctly.
        cache.setMatchingRequestParameterName(null);
        return cache;
    }

    @Bean
    public org.springframework.security.web.authentication.AuthenticationSuccessHandler authenticationSuccessHandler() {
        return (request, response, authentication) -> {
            org.springframework.security.web.savedrequest.SavedRequest savedRequest = requestCache().getRequest(request, response);
            if (savedRequest == null) {
                jakarta.servlet.http.HttpSession session = request.getSession(false);
                if (session != null) {
                    savedRequest = (org.springframework.security.web.savedrequest.SavedRequest) 
                            session.getAttribute("SPRING_SECURITY_SAVED_REQUEST");
                }
            }

            if (savedRequest != null) {
                String redirectUrl = savedRequest.getRedirectUrl();
                requestCache().removeRequest(request, response);
                jakarta.servlet.http.HttpSession session = request.getSession(false);
                if (session != null) {
                    session.removeAttribute("SPRING_SECURITY_SAVED_REQUEST");
                    if (redirectUrl != null && (redirectUrl.contains("prompt=login") || redirectUrl.contains("prompt%3Dlogin"))) {
                        session.setAttribute("PROMPT_LOGIN_SATISFIED", Boolean.TRUE);
                    }
                }
                if (redirectUrl != null) {
                    response.sendRedirect(redirectUrl);
                    return;
                }
            }

            response.sendRedirect("/");
        };
    }

    public static class PromptLoginFilter extends org.springframework.web.filter.OncePerRequestFilter {
        private final org.springframework.security.web.savedrequest.RequestCache requestCache;

        public PromptLoginFilter(org.springframework.security.web.savedrequest.RequestCache requestCache) {
            this.requestCache = requestCache;
        }

        @Override
        protected void doFilterInternal(jakarta.servlet.http.HttpServletRequest request,
                jakarta.servlet.http.HttpServletResponse response,
                jakarta.servlet.FilterChain filterChain) throws jakarta.servlet.ServletException, java.io.IOException {
            if (request.getRequestURI() != null && request.getRequestURI().startsWith("/oauth2/authorize")) {
                String prompt = request.getParameter("prompt");
                String queryString = request.getQueryString();
                boolean isPromptLogin = (prompt != null && prompt.contains("login"))
                        || (queryString != null && (queryString.contains("prompt=login") || queryString.contains("prompt%3Dlogin")));

                if (isPromptLogin) {
                    jakarta.servlet.http.HttpSession session = request.getSession(false);
                    if (session != null && Boolean.TRUE.equals(session.getAttribute("PROMPT_LOGIN_SATISFIED"))) {
                        session.removeAttribute("PROMPT_LOGIN_SATISFIED");
                    } else {
                        // Preserve the original OAuth authorization request before clearing context
                        requestCache.saveRequest(request, response);

                        if (session != null) {
                            session.removeAttribute(org.springframework.security.web.context.HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY);
                        }
                        org.springframework.security.core.context.SecurityContextHolder.clearContext();

                        // Redirect to /login
                        response.sendRedirect("/login");
                        return;
                    }
                }
            }
            filterChain.doFilter(request, response);
        }
    }

    /**
     * Spring Authorization Server Filter Chain (Priority Order 1).
     * Handles standard OAuth 2.1 protocol endpoints:
     * - /oauth2/authorize (Authorization Code + PKCE)
     * - /oauth2/token (Token & Refresh Token exchange)
     * - /oauth2/jwks (Public RSA keys)
     * - /.well-known/openid-configuration
     */
    @Bean
    @Order(1)
    public SecurityFilterChain authorizationServerSecurityFilterChain(HttpSecurity http,
            RegisteredClientRepository registeredClientRepository,
            AuthorizationServerSettings authorizationServerSettings) throws Exception {
        OAuth2AuthorizationServerConfigurer authorizationServerConfigurer = new OAuth2AuthorizationServerConfigurer();

        http
                .securityMatcher(authorizationServerConfigurer.getEndpointsMatcher())
                .with(authorizationServerConfigurer, authorizationServer -> authorizationServer
                        .authorizationServerSettings(authorizationServerSettings)
                        .oidc(Customizer.withDefaults())
                        .clientAuthentication(clientAuth -> {
                            clientAuth.authenticationConverter(new PublicClientRefreshTokenAuthenticationConverter());
                            clientAuth.authenticationProvider(
                                    new PublicClientRefreshTokenAuthenticationProvider(registeredClientRepository));
                        }))
                .authorizeHttpRequests(authorize -> authorize.anyRequest().authenticated())
                .requestCache(cache -> cache.requestCache(requestCache()))
                .addFilterAfter(new PromptLoginFilter(requestCache()), org.springframework.security.web.context.SecurityContextHolderFilter.class)
                .exceptionHandling(exceptions -> exceptions
                        .defaultAuthenticationEntryPointFor(
                                new LoginUrlAuthenticationEntryPoint("/login"),
                                new MediaTypeRequestMatcher(MediaType.TEXT_HTML)))
                .authenticationProvider(authenticationProvider())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()));

        return http.build();
    }

    /**
     * Application & OAuth2 Resource Server Filter Chain (Priority Order 2).
     * Handles /api/** REST endpoints and protects them using Bearer JWT tokens.
     */
    @Bean
    @Order(2)
    public SecurityFilterChain defaultSecurityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/api/auth/register", "/api/auth/login").permitAll()
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/login").permitAll()
                        .requestMatchers("/error").permitAll()
                        .requestMatchers("/oauth2/**", "/.well-known/**").permitAll()
                        .anyRequest().authenticated())
                .requestCache(cache -> cache.requestCache(requestCache()))
                .formLogin(form -> form
                        .loginPage("/login")
                        .permitAll()
                        .successHandler(authenticationSuccessHandler()))
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                        .authenticationEntryPoint(jwtAuthenticationEntryPoint))
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Registered Client Repository for OAuth 2.1.
     * Configures the Flutter mobile public client (no client_secret, PKCE
     * enforced).
     */
    @Bean
    public RegisteredClientRepository registeredClientRepository() {
        RegisteredClient mobileClient = RegisteredClient.withId("civicpulse-mobile-client-id")
                .clientId("civicpulse-mobile-client")
                .clientAuthenticationMethod(ClientAuthenticationMethod.NONE)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .redirectUri("civicpulse://oauth2redirect")
                .redirectUri("http://127.0.0.1:8080/authorized")
                .redirectUri("http://localhost:8080/authorized")
                .postLogoutRedirectUri("civicpulse://oauth2redirect")
                .scope(OidcScopes.OPENID)
                .scope(OidcScopes.PROFILE)
                .scope("offline_access")
                .scope("civicpulse.read")
                .scope("civicpulse.write")
                .clientSettings(ClientSettings.builder()
                        .requireProofKey(true)
                        .requireAuthorizationConsent(false)
                        .build())
                .tokenSettings(TokenSettings.builder()
                        .accessTokenTimeToLive(Duration.ofMinutes(15))
                        .refreshTokenTimeToLive(Duration.ofDays(30))
                        .reuseRefreshTokens(false)
                        .build())
                .build();

        return new InMemoryRegisteredClientRepository(mobileClient);
    }

    /**
     * Customizes JWT access tokens to include CivicPulse user roles and metadata.
     */
    @Bean
    public OAuth2TokenCustomizer<JwtEncodingContext> jwtTokenCustomizer(UserRepository userRepository) {
        return context -> {
            if (OAuth2TokenType.ACCESS_TOKEN.equals(context.getTokenType())) {
                Authentication principal = context.getPrincipal();
                Set<String> authorities = principal.getAuthorities().stream()
                        .map(GrantedAuthority::getAuthority)
                        .collect(Collectors.toSet());

                context.getClaims().claims(claims -> {
                    claims.put("roles", authorities);
                });

                userRepository.findByEmail(principal.getName()).ifPresent(user -> {
                    context.getClaims().claims(claims -> {
                        claims.put("userId", user.getUserId());
                        claims.put("fullName", user.getFullName());
                    });
                });
            }
        };
    }

    /**
     * Converts OAuth2 JWT claims to Spring Security GrantedAuthority collection.
     * Maps both 'scope' -> 'SCOPE_...' and 'roles' -> 'ROLE_...'.
     */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter defaultConverter = new JwtGrantedAuthoritiesConverter();

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Collection<GrantedAuthority> authorities = new ArrayList<>(defaultConverter.convert(jwt));

            Object rolesClaim = jwt.getClaim("roles");
            if (rolesClaim instanceof Collection<?> rolesList) {
                for (Object role : rolesList) {
                    if (role instanceof String roleStr) {
                        if (!roleStr.startsWith("ROLE_")) {
                            authorities.add(new SimpleGrantedAuthority("ROLE_" + roleStr));
                        } else {
                            authorities.add(new SimpleGrantedAuthority(roleStr));
                        }
                    }
                }
            } else if (rolesClaim instanceof String roleStr) {
                if (!roleStr.startsWith("ROLE_")) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_" + roleStr));
                } else {
                    authorities.add(new SimpleGrantedAuthority(roleStr));
                }
            }

            return authorities;
        });
        return converter;
    }

    /**
     * Generates an in-memory 2048-bit RSA Key Pair for asymmetric JWT signing in
     * development.
     */
    @Bean
    public JWKSource<SecurityContext> jwkSource() {
        RSAKey rsaKey = generateRsaKey();
        JWKSet jwkSet = new JWKSet(rsaKey);
        return (jwkSelector, securityContext) -> jwkSelector.select(jwkSet);
    }

    /**
     * Configures the OAuth2TokenGenerator supporting Access Tokens, ID Tokens, and
     * Refresh Tokens for PKCE clients.
     */
    @Bean
    public OAuth2TokenGenerator<?> tokenGenerator(JWKSource<SecurityContext> jwkSource,
            OAuth2TokenCustomizer<JwtEncodingContext> jwtTokenCustomizer) {
        NimbusJwtEncoder jwtEncoder = new NimbusJwtEncoder(jwkSource);
        JwtGenerator jwtGenerator = new JwtGenerator(jwtEncoder);
        if (jwtTokenCustomizer != null) {
            jwtGenerator.setJwtCustomizer(jwtTokenCustomizer);
        }
        OAuth2AccessTokenGenerator accessTokenGenerator = new OAuth2AccessTokenGenerator();

        StringKeyGenerator refreshTokenStringGenerator = new Base64StringKeyGenerator(
                Base64.getUrlEncoder().withoutPadding(), 96);
        OAuth2TokenGenerator<OAuth2RefreshToken> refreshTokenGenerator = context -> {
            if (!OAuth2TokenType.REFRESH_TOKEN.equals(context.getTokenType())) {
                return null;
            }
            if (context.getRegisteredClient() == null ||
                    !context.getRegisteredClient().getAuthorizationGrantTypes()
                            .contains(AuthorizationGrantType.REFRESH_TOKEN)) {
                return null;
            }
            Instant issuedAt = Instant.now();
            Duration timeToLive = context.getRegisteredClient().getTokenSettings().getRefreshTokenTimeToLive();
            Instant expiresAt = issuedAt.plus(timeToLive);
            return new OAuth2RefreshToken(refreshTokenStringGenerator.generateKey(), issuedAt, expiresAt);
        };

        return new DelegatingOAuth2TokenGenerator(jwtGenerator, accessTokenGenerator, refreshTokenGenerator);
    }

    private static RSAKey generateRsaKey() {
        KeyPair keyPair = generateKeyPair();
        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
        RSAPrivateKey privateKey = (RSAPrivateKey) keyPair.getPrivate();
        return new RSAKey.Builder(publicKey)
                .privateKey(privateKey)
                .keyUse(com.nimbusds.jose.jwk.KeyUse.SIGNATURE)
                .keyID(UUID.randomUUID().toString())
                .build();
    }

    private static KeyPair generateKeyPair() {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            return keyPairGenerator.generateKeyPair();
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to generate RSA key pair", ex);
        }
    }

    @Bean
    public JwtDecoder jwtDecoder(JWKSource<SecurityContext> jwkSource) {
        return OAuth2AuthorizationServerConfiguration.jwtDecoder(jwkSource);
    }

    @Bean
    public AuthorizationServerSettings authorizationServerSettings(
            @Value("${civicpulse.oauth2.issuer-url:${AUTH_ISSUER_URL:http://localhost:8080}}") String issuerUrl) {
        String cleanIssuerUrl = (issuerUrl != null && !issuerUrl.trim().isEmpty())
                ? issuerUrl.trim()
                : "http://localhost:8080";
        if (cleanIssuerUrl.endsWith("/")) {
            cleanIssuerUrl = cleanIssuerUrl.substring(0, cleanIssuerUrl.length() - 1);
        }
        return AuthorizationServerSettings.builder()
                .issuer(cleanIssuerUrl)
                .build();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration
                .setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With", "Accept", "Origin"));
        configuration.setExposedHeaders(List.of("Authorization"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
