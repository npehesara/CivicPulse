package civicpulse_backend.service;

import civicpulse_backend.dto.notification.NotificationResponse;
import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.Notification;
import civicpulse_backend.entity.NotificationType;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.NotificationRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final SecurityUtils securityUtils;

    public NotificationService(NotificationRepository notificationRepository, SecurityUtils securityUtils) {
        this.notificationRepository = notificationRepository;
        this.securityUtils = securityUtils;
    }

    @Transactional
    public Notification createNotification(User user, Issue issue, String title, String message, NotificationType type) {
        if (user == null) return null;
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setIssue(issue);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setNotificationType(type);
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());
        return notificationRepository.save(notification);
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getCurrentUserNotifications() {
        User currentUser = securityUtils.getCurrentUser();
        return notificationRepository.findByUser_UserIdOrderByCreatedAtDesc(currentUser.getUserId())
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getCurrentUserUnreadNotifications() {
        User currentUser = securityUtils.getCurrentUser();
        return notificationRepository.findByUser_UserIdAndIsReadFalseOrderByCreatedAtDesc(currentUser.getUserId())
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public NotificationResponse markAsRead(Long id) {
        User currentUser = securityUtils.getCurrentUser();
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with id: " + id));

        if (!notification.getUser().getUserId().equals(currentUser.getUserId())) {
            throw new UnauthorizedOperationException("Cannot modify notifications of other users");
        }

        notification.setIsRead(true);
        Notification saved = notificationRepository.save(notification);
        return NotificationResponse.fromEntity(saved);
    }

    @Transactional
    public void markAllAsRead() {
        User currentUser = securityUtils.getCurrentUser();
        List<Notification> unreadList = notificationRepository.findByUser_UserIdAndIsReadFalseOrderByCreatedAtDesc(currentUser.getUserId());
        for (Notification notification : unreadList) {
            notification.setIsRead(true);
        }
        notificationRepository.saveAll(unreadList);
    }
}
