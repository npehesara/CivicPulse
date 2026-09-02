package civicpulse_backend.service;

import civicpulse_backend.dto.moderation.ModerationRequest;
import civicpulse_backend.dto.moderation.ModerationResponse;
import civicpulse_backend.entity.*;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.ModerationRepository;
import civicpulse_backend.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ModerationServiceTest {

    @Mock
    private ModerationRepository moderationRepository;
    @Mock
    private IssueRepository issueRepository;
    @Mock
    private NotificationService notificationService;
    @Mock
    private SecurityUtils securityUtils;

    @InjectMocks
    private ModerationService moderationService;

    private User moderator;
    private User reporter;
    private Issue issue;
    private Moderation moderation;

    @BeforeEach
    void setUp() {
        moderator = new User("Mod", "mod@gov.lk", "hash", null, Role.ADMIN, AccountStatus.ACTIVE);
        moderator.setUserId(99L);

        reporter = new User("Reporter", "rep@example.com", "hash", null, Role.CITIZEN, AccountStatus.ACTIVE);
        reporter.setUserId(1L);

        issue = new Issue();
        issue.setIssueId(1L);
        issue.setTitle("Suspicious post");
        issue.setUser(reporter);

        moderation = new Moderation(issue);
        moderation.setModerationId(5L);
        moderation.setCreatedAt(LocalDateTime.now());
    }

    @Test
    void shouldCreateOrUpdateModerationForIssue() {
        ModerationRequest request = new ModerationRequest();
        request.setToxicityScore(0.85);
        request.setTextModerationStatus(ModerationStatus.FLAGGED);

        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(moderationRepository.findByIssue_IssueId(1L)).thenReturn(Optional.of(moderation));
        when(securityUtils.getCurrentUser()).thenReturn(moderator);
        when(moderationRepository.save(any(Moderation.class))).thenReturn(moderation);

        ModerationResponse response = moderationService.createOrUpdateModerationForIssue(1L, request);
        assertNotNull(response);
        assertEquals(5L, response.getModerationId());
        verify(notificationService).createNotification(eq(reporter), eq(issue), anyString(), anyString(), eq(NotificationType.MODERATION_ALERT));
    }
}
