package civicpulse_backend.service;

import civicpulse_backend.dto.assignment.CreateAssignmentRequest;
import civicpulse_backend.dto.assignment.AssignmentResponse;
import civicpulse_backend.dto.assignment.UpdateAssignmentRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.DepartmentRepository;
import civicpulse_backend.repository.IssueAssignmentRepository;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class IssueAssignmentService {

    private final IssueAssignmentRepository assignmentRepository;
    private final IssueRepository issueRepository;
    private final DepartmentRepository departmentRepository;
    private final UserRepository userRepository;
    private final IssueStatusService statusService;
    private final NotificationService notificationService;

    public IssueAssignmentService(IssueAssignmentRepository assignmentRepository,
                                  IssueRepository issueRepository,
                                  DepartmentRepository departmentRepository,
                                  UserRepository userRepository,
                                  IssueStatusService statusService,
                                  NotificationService notificationService) {
        this.assignmentRepository = assignmentRepository;
        this.issueRepository = issueRepository;
        this.departmentRepository = departmentRepository;
        this.userRepository = userRepository;
        this.statusService = statusService;
        this.notificationService = notificationService;
    }

    @Transactional
    public AssignmentResponse createAssignment(Long issueId, CreateAssignmentRequest request) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + issueId));

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + request.getDepartmentId()));

        User assignedUser = null;
        if (request.getAssignedUserId() != null) {
            assignedUser = userRepository.findById(request.getAssignedUserId())
                    .orElseThrow(() -> new ResourceNotFoundException("Assigned user not found with id: " + request.getAssignedUserId()));
        }

        IssueAssignment assignment = new IssueAssignment();
        assignment.setIssue(issue);
        assignment.setDepartment(department);
        assignment.setAssignedUser(assignedUser);
        assignment.setAssignedAt(LocalDateTime.now());

        IssueAssignment saved = assignmentRepository.save(assignment);

        // Update issue department and set status to ASSIGNED if currently in initial status
        issue.setDepartment(department);
        if ("REPORTED".equalsIgnoreCase(issue.getStatus().getStatusName()) || "UNDER_REVIEW".equalsIgnoreCase(issue.getStatus().getStatusName())) {
            IssueStatus assignedStatus = statusService.getOrCreateStatus("ASSIGNED", "Issue assigned to department");
            issue.setStatus(assignedStatus);
            issue.setUpdatedAt(LocalDateTime.now());
            issueRepository.save(issue);
        }

        // Send notifications
        notificationService.createNotification(
                issue.getUser(),
                issue,
                "Issue Assigned",
                "Your issue '" + issue.getTitle() + "' has been assigned to department " + department.getDepartmentName(),
                NotificationType.ASSIGNMENT_CREATED
        );

        if (assignedUser != null) {
            notificationService.createNotification(
                    assignedUser,
                    issue,
                    "New Task Assignment",
                    "You have been assigned to handle issue '" + issue.getTitle() + "'",
                    NotificationType.ASSIGNMENT_CREATED
            );
        }

        return AssignmentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<AssignmentResponse> getAssignmentsForIssue(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        return assignmentRepository.findByIssue_IssueIdOrderByAssignedAtDesc(issueId).stream()
                .map(AssignmentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public AssignmentResponse updateAssignment(Long assignmentId, UpdateAssignmentRequest request) {
        IssueAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Assignment not found with id: " + assignmentId));

        if (request.getDepartmentId() != null) {
            Department department = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + request.getDepartmentId()));
            assignment.setDepartment(department);
        }

        if (request.getAssignedUserId() != null) {
            User assignedUser = userRepository.findById(request.getAssignedUserId())
                    .orElseThrow(() -> new ResourceNotFoundException("Assigned user not found with id: " + request.getAssignedUserId()));
            assignment.setAssignedUser(assignedUser);
        }

        if (Boolean.TRUE.equals(request.getMarkCompleted())) {
            assignment.setCompletedAt(LocalDateTime.now());
        }

        IssueAssignment saved = assignmentRepository.save(assignment);
        return AssignmentResponse.fromEntity(saved);
    }

    @Transactional
    public void deleteAssignment(Long assignmentId) {
        if (!assignmentRepository.existsById(assignmentId)) {
            throw new ResourceNotFoundException("Assignment not found with id: " + assignmentId);
        }
        assignmentRepository.deleteById(assignmentId);
    }
}
