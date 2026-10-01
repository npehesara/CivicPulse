package civicpulse_backend.service;

import civicpulse_backend.entity.AccountStatus;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class AdminBootstrapService implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrapService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${CIVICPULSE_ADMIN_BOOTSTRAP_EMAIL:#{null}}")
    private String bootstrapEmail;

    @Value("${CIVICPULSE_ADMIN_BOOTSTRAP_PASSWORD:#{null}}")
    private String bootstrapPassword;

    public AdminBootstrapService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (bootstrapEmail == null || bootstrapEmail.isBlank() || bootstrapPassword == null || bootstrapPassword.isBlank()) {
            log.info("Admin bootstrap credentials are not configured. Skipping admin bootstrap.");
            return;
        }

        String normalizedEmail = bootstrapEmail.trim().toLowerCase();

        Optional<User> existingUserOpt = userRepository.findByEmail(normalizedEmail);

        if (existingUserOpt.isPresent()) {
            User existingUser = existingUserOpt.get();
            if (existingUser.getRole() == Role.ADMIN) {
                log.info("Admin user with email {} already exists. Skipping bootstrap.", normalizedEmail);
            } else {
                log.warn("A user with email {} already exists but is not an ADMIN. Bootstrap will not promote existing users.", normalizedEmail);
            }
            return;
        }

        log.info("Bootstrapping initial Admin user with email {}", normalizedEmail);
        
        User adminUser = new User();
        adminUser.setFullName("System Administrator");
        adminUser.setEmail(normalizedEmail);
        adminUser.setPasswordHash(passwordEncoder.encode(bootstrapPassword));
        adminUser.setRole(Role.ADMIN);
        adminUser.setAccountStatus(AccountStatus.ACTIVE);

        userRepository.save(adminUser);
        log.info("Successfully bootstrapped initial Admin user.");
    }
}
