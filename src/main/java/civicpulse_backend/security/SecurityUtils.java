package civicpulse_backend.security;

import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.InvalidCredentialsException;
import civicpulse_backend.repository.UserRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class SecurityUtils {

    private final UserRepository userRepository;

    public SecurityUtils(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public String getCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new InvalidCredentialsException("User is not authenticated");
        }
        return authentication.getName();
    }

    public User getCurrentUser() {
        String email = getCurrentUserEmail();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("Authenticated user not found"));
    }

    public boolean isCurrentUserAdminOrOfficial() {
        User user = getCurrentUser();
        return user.getRole() == Role.ADMIN || user.getRole() == Role.OFFICIAL;
    }

    public boolean isCurrentUserAdmin() {
        User user = getCurrentUser();
        return user.getRole() == Role.ADMIN;
    }
}
