package civicpulse_backend.service;

import civicpulse_backend.dto.issue.CreateIssueRequest;
import civicpulse_backend.dto.issue.IssueResponse;
import civicpulse_backend.dto.issue.UpdateIssueRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.*;
import civicpulse_backend.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IssueServiceTest {

    @Mock
    private IssueRepository issueRepository;
    @Mock
    private IssueCategoryRepository categoryRepository;
    @Mock
    private TerritoryRepository territoryRepository;
    @Mock
    private DepartmentRepository departmentRepository;
    @Mock
    private IssueStatusRepository statusRepository;
    @Mock
    private IssueStatusService statusService;
    @Mock
    private ModerationRepository moderationRepository;
    @Mock
    private UpvoteRepository upvoteRepository;
    @Mock
    private CommentRepository commentRepository;
    @Mock
    private NotificationService notificationService;
    @Mock
    private SecurityUtils securityUtils;

    @InjectMocks
    private IssueService issueService;

    private User user;
    private User otherUser;
    private IssueCategory category;
    private IssueStatus reportedStatus;
    private Issue issue;

    @BeforeEach
    void setUp() {
        user = new User("John Citizen", "john@example.com", "hash", "0771234567", Role.CITIZEN, AccountStatus.ACTIVE);
        user.setUserId(1L);

        otherUser = new User("Jane Citizen", "jane@example.com", "hash", "0777654321", Role.CITIZEN, AccountStatus.ACTIVE);
        otherUser.setUserId(2L);

        category = new IssueCategory("Roads", "Road issues");
        category.setCategoryId(1L);

        reportedStatus = new IssueStatus("REPORTED", "Reported by citizen");
        reportedStatus.setStatusId(1L);

        issue = new Issue();
        issue.setIssueId(1L);
        issue.setTitle("Pothole on Main St");
        issue.setDescription("Deep pothole near crossing");
        issue.setUser(user);
        issue.setCategory(category);
        issue.setStatus(reportedStatus);
        issue.setCreatedAt(LocalDateTime.now());
        issue.setUpdatedAt(LocalDateTime.now());
    }

    @Test
    void shouldCreateIssueSuccessfully() {
        CreateIssueRequest request = new CreateIssueRequest();
        request.setTitle("Pothole on Main St");
        request.setDescription("Deep pothole near crossing");
        request.setCategoryId(1L);

        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));
        when(statusService.getOrCreateStatus(eq("REPORTED"), anyString())).thenReturn(reportedStatus);
        when(issueRepository.save(any(Issue.class))).thenReturn(issue);

        IssueResponse response = issueService.createIssue(request);

        assertNotNull(response);
        assertEquals("Pothole on Main St", response.getTitle());
        assertEquals("REPORTED", response.getStatusName());
        verify(moderationRepository).save(any(Moderation.class));
        verify(notificationService).createNotification(eq(user), any(Issue.class), anyString(), anyString(), eq(NotificationType.ISSUE_CREATED));
    }

    @Test
    void shouldThrowExceptionWhenCategoryNotFoundOnCreate() {
        CreateIssueRequest request = new CreateIssueRequest();
        request.setTitle("Pothole on Main St");
        request.setDescription("Deep pothole near crossing");
        request.setCategoryId(999L);

        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> issueService.createIssue(request));
    }

    @Test
    void shouldGetIssueById() {
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(upvoteRepository.countByIssue_IssueId(1L)).thenReturn(5L);
        when(commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(1L)).thenReturn(Collections.emptyList());

        IssueResponse response = issueService.getIssueById(1L);
        assertNotNull(response);
        assertEquals(1L, response.getIssueId());
        assertEquals(5L, response.getUpvoteCount());
    }

    @Test
    void shouldGetIssuesPaginated() {
        Page<Issue> page = new PageImpl<>(List.of(issue));
        when(issueRepository.findAll(any(Specification.class), any(PageRequest.class))).thenReturn(page);
        when(upvoteRepository.countByIssue_IssueId(1L)).thenReturn(2L);
        when(commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(1L)).thenReturn(Collections.emptyList());

        when(securityUtils.getCurrentUser()).thenReturn(user);
        Page<IssueResponse> result = issueService.getIssues(null, null, null, null, null, null, null, null, PageRequest.of(0, 10));
        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
    }

    @Test
    void shouldUpdateIssueByOwner() {
        UpdateIssueRequest request = new UpdateIssueRequest();
        request.setTitle("Updated Title");

        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(issueRepository.save(any(Issue.class))).thenReturn(issue);

        IssueResponse response = issueService.updateIssue(1L, request);
        assertNotNull(response);
        verify(issueRepository).save(issue);
    }

    @Test
    void shouldThrowExceptionWhenUnauthorizedUserUpdatesIssue() {
        UpdateIssueRequest request = new UpdateIssueRequest();
        request.setTitle("Hacked Title");

        when(securityUtils.getCurrentUser()).thenReturn(otherUser);
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));

        assertThrows(UnauthorizedOperationException.class, () -> issueService.updateIssue(1L, request));
    }

    @Test
    void shouldDeleteIssueByOwner() {
        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));

        issueService.deleteIssue(1L);
        verify(issueRepository).delete(issue);
    }
}
