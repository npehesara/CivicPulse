package civicpulse_backend.service;

import civicpulse_backend.dto.assignment.AssignmentResponse;
import civicpulse_backend.dto.assignment.CreateAssignmentRequest;
import civicpulse_backend.dto.assignment.UpdateAssignmentRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.repository.DepartmentRepository;
import civicpulse_backend.repository.IssueAssignmentRepository;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.UserRepository;
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
class AssignmentServiceTest {

    @Mock
    private IssueAssignmentRepository assignmentRepository;
    @Mock
    private IssueRepository issueRepository;
    @Mock
    private DepartmentRepository departmentRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private IssueStatusService statusService;
    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private IssueAssignmentService assignmentService;

    private Issue issue;
    private Department department;
    private User official;
    private IssueAssignment assignment;

    @BeforeEach
    void setUp() {
        User citizen = new User("Citizen", "cit@example.com", "hash", null, Role.CITIZEN, AccountStatus.ACTIVE);
        citizen.setUserId(1L);

        official = new User("Officer Bob", "bob@example.com", "hash", null, Role.OFFICIAL, AccountStatus.ACTIVE);
        official.setUserId(2L);

        IssueStatus reportedStatus = new IssueStatus("REPORTED", "Reported");
        reportedStatus.setStatusId(1L);

        issue = new Issue();
        issue.setIssueId(1L);
        issue.setTitle("Broken Streetlight");
        issue.setUser(citizen);
        issue.setStatus(reportedStatus);

        department = new Department("Electrical Dept", "Lighting and Power", "123", "elec@city.gov", null);
        department.setDepartmentId(1L);

        assignment = new IssueAssignment(issue, department, official);
        assignment.setAssignmentId(10L);
        assignment.setAssignedAt(LocalDateTime.now());
    }

    @Test
    void shouldCreateAssignmentSuccessfully() {
        CreateAssignmentRequest request = new CreateAssignmentRequest(1L, 2L);
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(departmentRepository.findById(1L)).thenReturn(Optional.of(department));
        when(userRepository.findById(2L)).thenReturn(Optional.of(official));
        when(statusService.getOrCreateStatus(eq("ASSIGNED"), anyString())).thenReturn(new IssueStatus("ASSIGNED", "Assigned"));
        when(assignmentRepository.save(any(IssueAssignment.class))).thenReturn(assignment);

        AssignmentResponse response = assignmentService.createAssignment(1L, request);
        assertNotNull(response);
        assertEquals(10L, response.getAssignmentId());
        assertEquals("Electrical Dept", response.getDepartmentName());
        verify(notificationService, atLeastOnce()).createNotification(any(), any(), anyString(), anyString(), eq(NotificationType.ASSIGNMENT_CREATED));
    }

    @Test
    void shouldUpdateAndCompleteAssignment() {
        UpdateAssignmentRequest request = new UpdateAssignmentRequest();
        request.setMarkCompleted(true);

        when(assignmentRepository.findById(10L)).thenReturn(Optional.of(assignment));
        when(assignmentRepository.save(any(IssueAssignment.class))).thenReturn(assignment);

        AssignmentResponse response = assignmentService.updateAssignment(10L, request);
        assertNotNull(response);
        assertNotNull(assignment.getCompletedAt());
    }
}
