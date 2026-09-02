package civicpulse_backend.service;

import civicpulse_backend.dto.notification.NotificationResponse;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.NotificationRepository;
import civicpulse_backend.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;
    @Mock
    private SecurityUtils securityUtils;

    @InjectMocks
    private NotificationService notificationService;

    private User user;
    private User otherUser;
    private Notification notification;

    @BeforeEach
    void setUp() {
        user = new User("John", "john@example.com", "hash", null, Role.CITIZEN, AccountStatus.ACTIVE);
        user.setUserId(1L);

        otherUser = new User("Jane", "jane@example.com", "hash", null, Role.CITIZEN, AccountStatus.ACTIVE);
        otherUser.setUserId(2L);

        notification = new Notification("Alert", "Something happened", NotificationType.STATUS_UPDATED, user, null);
        notification.setNotificationId(1L);
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());
    }

    @Test
    void shouldCreateNotification() {
        when(notificationRepository.save(any(Notification.class))).thenReturn(notification);

        Notification created = notificationService.createNotification(user, null, "Alert", "Something happened", NotificationType.STATUS_UPDATED);
        assertNotNull(created);
        assertEquals("Alert", created.getTitle());
    }

    @Test
    void shouldGetUserNotifications() {
        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(notificationRepository.findByUser_UserIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(notification));

        List<NotificationResponse> list = notificationService.getCurrentUserNotifications();
        assertEquals(1, list.size());
    }

    @Test
    void shouldMarkNotificationAsRead() {
        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(notificationRepository.findById(1L)).thenReturn(Optional.of(notification));
        when(notificationRepository.save(any(Notification.class))).thenReturn(notification);

        NotificationResponse response = notificationService.markAsRead(1L);
        assertNotNull(response);
        assertTrue(notification.getIsRead());
    }

    @Test
    void shouldPreventMarkingOtherUsersNotificationAsRead() {
        when(securityUtils.getCurrentUser()).thenReturn(otherUser);
        when(notificationRepository.findById(1L)).thenReturn(Optional.of(notification));

        assertThrows(UnauthorizedOperationException.class, () -> notificationService.markAsRead(1L));
    }
}
