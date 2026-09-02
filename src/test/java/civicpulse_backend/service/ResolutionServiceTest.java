package civicpulse_backend.service;

import civicpulse_backend.dto.resolution.CreateResolutionRequest;
import civicpulse_backend.dto.resolution.ResolutionResponse;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.ResolutionRepository;
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
class ResolutionServiceTest {

    @Mock
    private ResolutionRepository resolutionRepository;
    @Mock
    private IssueRepository issueRepository;
    @Mock
    private IssueStatusService statusService;
    @Mock
    private NotificationService notificationService;
    @Mock
    private SecurityUtils securityUtils;

    @InjectMocks
    private ResolutionService resolutionService;

    private User official;
    private User citizen;
    private Issue issue;
    private Resolution resolution;

    @BeforeEach
    void setUp() {
        official = new User("Official Jane", "jane@gov.lk", "hash", null, Role.OFFICIAL, AccountStatus.ACTIVE);
        official.setUserId(2L);

        citizen = new User("Citizen Bob", "bob@example.com", "hash", null, Role.CITIZEN, AccountStatus.ACTIVE);
        citizen.setUserId(1L);

        issue = new Issue();
        issue.setIssueId(1L);
        issue.setTitle("Water Leak");
        issue.setUser(citizen);

        resolution = new Resolution("Pipe repaired successfully", "https://image.url/proof.jpg", issue, official);
        resolution.setResolutionId(10L);
        resolution.setResolvedAt(LocalDateTime.now());
    }

    @Test
    void shouldCreateResolutionSuccessfully() {
        CreateResolutionRequest request = new CreateResolutionRequest("Pipe repaired successfully", "https://image.url/proof.jpg");
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(securityUtils.getCurrentUser()).thenReturn(official);
        when(resolutionRepository.existsByIssue_IssueId(1L)).thenReturn(false);
        when(resolutionRepository.save(any(Resolution.class))).thenReturn(resolution);
        when(statusService.getOrCreateStatus(eq("RESOLVED"), anyString())).thenReturn(new IssueStatus("RESOLVED", "Resolved"));

        ResolutionResponse response = resolutionService.createResolution(1L, request);
        assertNotNull(response);
        assertEquals(10L, response.getResolutionId());
        assertEquals("Pipe repaired successfully", response.getResolutionDescription());
        verify(issueRepository).save(issue);
        verify(notificationService).createNotification(eq(citizen), eq(issue), anyString(), anyString(), eq(NotificationType.ISSUE_RESOLVED));
    }

    @Test
    void shouldPreventDuplicateResolution() {
        CreateResolutionRequest request = new CreateResolutionRequest("Another fix", null);
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(securityUtils.getCurrentUser()).thenReturn(official);
        when(resolutionRepository.existsByIssue_IssueId(1L)).thenReturn(true);

        assertThrows(ConflictException.class, () -> resolutionService.createResolution(1L, request));
    }

    @Test
    void shouldPreventCitizenFromCreatingResolution() {
        CreateResolutionRequest request = new CreateResolutionRequest("Fixed it myself", null);
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(securityUtils.getCurrentUser()).thenReturn(citizen);

        assertThrows(UnauthorizedOperationException.class, () -> resolutionService.createResolution(1L, request));
    }
}
