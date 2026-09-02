package civicpulse_backend.service;

import civicpulse_backend.dto.issue.CreateIssueRequest;
import civicpulse_backend.dto.issue.IssueResponse;
import civicpulse_backend.dto.issue.UpdateIssueRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.*;
import civicpulse_backend.security.SecurityUtils;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class IssueService {

    private final IssueRepository issueRepository;
    private final IssueCategoryRepository categoryRepository;
    private final TerritoryRepository territoryRepository;
    private final DepartmentRepository departmentRepository;
    private final IssueStatusRepository statusRepository;
    private final IssueStatusService statusService;
    private final ModerationRepository moderationRepository;
    private final UpvoteRepository upvoteRepository;
    private final CommentRepository commentRepository;
    private final NotificationService notificationService;
    private final SecurityUtils securityUtils;

    public IssueService(IssueRepository issueRepository,
                        IssueCategoryRepository categoryRepository,
                        TerritoryRepository territoryRepository,
                        DepartmentRepository departmentRepository,
                        IssueStatusRepository statusRepository,
                        IssueStatusService statusService,
                        ModerationRepository moderationRepository,
                        UpvoteRepository upvoteRepository,
                        CommentRepository commentRepository,
                        NotificationService notificationService,
                        SecurityUtils securityUtils) {
        this.issueRepository = issueRepository;
        this.categoryRepository = categoryRepository;
        this.territoryRepository = territoryRepository;
        this.departmentRepository = departmentRepository;
        this.statusRepository = statusRepository;
        this.statusService = statusService;
        this.moderationRepository = moderationRepository;
        this.upvoteRepository = upvoteRepository;
        this.commentRepository = commentRepository;
        this.notificationService = notificationService;
        this.securityUtils = securityUtils;
    }

    @Transactional
    public IssueResponse createIssue(CreateIssueRequest request) {
        User currentUser = securityUtils.getCurrentUser();

        IssueCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + request.getCategoryId()));

        Issue issue = new Issue();
        issue.setTitle(request.getTitle().trim());
        issue.setDescription(request.getDescription().trim());
        issue.setLatitude(request.getLatitude());
        issue.setLongitude(request.getLongitude());
        issue.setLocationPoint(request.getLocationPoint());
        issue.setVisibility(request.getVisibility() != null ? request.getVisibility() : Visibility.PUBLIC);
        issue.setSeverity(request.getSeverity() != null ? request.getSeverity() : Severity.MEDIUM);
        issue.setIsTransitReport(request.getIsTransitReport() != null ? request.getIsTransitReport() : false);
        issue.setUser(currentUser);
        issue.setCategory(category);
        issue.setCreatedAt(LocalDateTime.now());
        issue.setUpdatedAt(LocalDateTime.now());

        if (request.getTerritoryId() != null) {
            Territory territory = territoryRepository.findById(request.getTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + request.getTerritoryId()));
            issue.setTerritory(territory);
        }

        if (request.getDepartmentId() != null) {
            Department department = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + request.getDepartmentId()));
            issue.setDepartment(department);
        }

        IssueStatus reportedStatus = statusService.getOrCreateStatus("REPORTED", "Issue reported by citizen");
        issue.setStatus(reportedStatus);

        Issue savedIssue = issueRepository.save(issue);

        // Initialize empty moderation record for AI/manual moderation
        Moderation moderation = new Moderation(savedIssue);
        moderationRepository.save(moderation);

        // Send submission notification
        notificationService.createNotification(
                currentUser,
                savedIssue,
                "Issue Submitted",
                "Your issue '" + savedIssue.getTitle() + "' has been submitted successfully.",
                NotificationType.ISSUE_CREATED
        );

        return IssueResponse.fromEntity(savedIssue, 0L, 0L);
    }

    @Transactional(readOnly = true)
    public Page<IssueResponse> getIssues(Long categoryId,
                                         Long statusId,
                                         Long territoryId,
                                         Severity severity,
                                         Visibility visibility,
                                         Long departmentId,
                                         Long userId,
                                         String keyword,
                                         Pageable pageable) {
        User currentUser = securityUtils.getCurrentUser();
        boolean isStaff = currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.OFFICIAL;

        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (categoryId != null) {
                predicates.add(cb.equal(root.get("category").get("categoryId"), categoryId));
            }
            if (statusId != null) {
                predicates.add(cb.equal(root.get("status").get("statusId"), statusId));
            }
            if (territoryId != null) {
                predicates.add(cb.equal(root.get("territory").get("territoryId"), territoryId));
            }
            if (severity != null) {
                predicates.add(cb.equal(root.get("severity"), severity));
            }
            if (departmentId != null) {
                predicates.add(cb.equal(root.get("department").get("departmentId"), departmentId));
            }

            if (userId != null) {
                predicates.add(cb.equal(root.get("user").get("userId"), userId));
                if (!isStaff && !currentUser.getUserId().equals(userId)) {
                    predicates.add(cb.equal(root.get("visibility"), Visibility.PUBLIC));
                }
            } else if (!isStaff) {
                if (visibility != null) {
                    if (visibility == Visibility.PRIVATE) {
                        predicates.add(cb.and(
                                cb.equal(root.get("visibility"), Visibility.PRIVATE),
                                cb.equal(root.get("user").get("userId"), currentUser.getUserId())
                        ));
                    } else {
                        predicates.add(cb.equal(root.get("visibility"), Visibility.PUBLIC));
                    }
                } else {
                    predicates.add(cb.or(
                            cb.equal(root.get("visibility"), Visibility.PUBLIC),
                            cb.equal(root.get("user").get("userId"), currentUser.getUserId())
                    ));
                }
            } else if (visibility != null) {
                predicates.add(cb.equal(root.get("visibility"), visibility));
            }

            if (keyword != null && !keyword.isBlank()) {
                String searchPattern = "%" + keyword.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("title")), searchPattern),
                        cb.like(cb.lower(root.get("description")), searchPattern)
                ));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Issue> issues = issueRepository.findAll(spec, pageable);
        return issues.map(issue -> {
            long upvotes = upvoteRepository.countByIssue_IssueId(issue.getIssueId());
            long comments = commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(issue.getIssueId()).size();
            return IssueResponse.fromEntity(issue, upvotes, comments);
        });
    }

    @Transactional(readOnly = true)
    public IssueResponse getIssueById(Long id) {
        Issue issue = issueRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + id));

        if (issue.getVisibility() == Visibility.PRIVATE) {
            User currentUser = null;
            try {
                currentUser = securityUtils.getCurrentUser();
            } catch (Exception ignored) {
            }
            boolean isStaff = currentUser != null && (currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.OFFICIAL);
            boolean isOwner = currentUser != null && issue.getUser() != null && issue.getUser().getUserId().equals(currentUser.getUserId());
            if (!isOwner && !isStaff) {
                throw new UnauthorizedOperationException("You do not have permission to view this private issue");
            }
        }

        long upvotes = upvoteRepository.countByIssue_IssueId(issue.getIssueId());
        long comments = commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(issue.getIssueId()).size();
        return IssueResponse.fromEntity(issue, upvotes, comments);
    }

    @Transactional
    public IssueResponse updateIssue(Long id, UpdateIssueRequest request) {
        User currentUser = securityUtils.getCurrentUser();
        Issue issue = issueRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + id));

        boolean isOwner = issue.getUser().getUserId().equals(currentUser.getUserId());
        boolean isStaff = currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.OFFICIAL;

        if (!isOwner && !isStaff) {
            throw new UnauthorizedOperationException("You do not have permission to update this issue");
        }

        if (request.getTitle() != null) issue.setTitle(request.getTitle().trim());
        if (request.getDescription() != null) issue.setDescription(request.getDescription().trim());
        if (request.getLatitude() != null) issue.setLatitude(request.getLatitude());
        if (request.getLongitude() != null) issue.setLongitude(request.getLongitude());
        if (request.getLocationPoint() != null) issue.setLocationPoint(request.getLocationPoint());
        if (request.getVisibility() != null) issue.setVisibility(request.getVisibility());
        if (request.getSeverity() != null) issue.setSeverity(request.getSeverity());
        if (request.getIsTransitReport() != null) issue.setIsTransitReport(request.getIsTransitReport());

        if (request.getCategoryId() != null) {
            IssueCategory category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + request.getCategoryId()));
            issue.setCategory(category);
        }

        if (request.getTerritoryId() != null) {
            Territory territory = territoryRepository.findById(request.getTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + request.getTerritoryId()));
            issue.setTerritory(territory);
        }

        if (request.getDepartmentId() != null) {
            Department department = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + request.getDepartmentId()));
            issue.setDepartment(department);
        }

        if (request.getStatusId() != null) {
            if (!isStaff) {
                throw new UnauthorizedOperationException("Only officials and administrators can update issue status");
            }
            IssueStatus newStatus = statusRepository.findById(request.getStatusId())
                    .orElseThrow(() -> new ResourceNotFoundException("Status not found with id: " + request.getStatusId()));
            
            if (!issue.getStatus().getStatusId().equals(newStatus.getStatusId())) {
                issue.setStatus(newStatus);
                // Notify issue owner of status change
                notificationService.createNotification(
                        issue.getUser(),
                        issue,
                        "Issue Status Changed",
                        "The status of your issue '" + issue.getTitle() + "' was updated to " + newStatus.getStatusName(),
                        NotificationType.STATUS_UPDATED
                );
            }
        }

        issue.setUpdatedAt(LocalDateTime.now());
        Issue saved = issueRepository.save(issue);

        long upvotes = upvoteRepository.countByIssue_IssueId(saved.getIssueId());
        long comments = commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(saved.getIssueId()).size();
        return IssueResponse.fromEntity(saved, upvotes, comments);
    }

    @Transactional
    public void deleteIssue(Long id) {
        User currentUser = securityUtils.getCurrentUser();
        Issue issue = issueRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + id));

        boolean isOwner = issue.getUser().getUserId().equals(currentUser.getUserId());
        boolean isAdmin = currentUser.getRole() == Role.ADMIN;

        if (!isOwner && !isAdmin) {
            throw new UnauthorizedOperationException("You do not have permission to delete this issue");
        }

        issueRepository.delete(issue);
    }
}
