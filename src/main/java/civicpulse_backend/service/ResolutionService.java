package civicpulse_backend.service;

import civicpulse_backend.dto.resolution.CreateResolutionRequest;
import civicpulse_backend.dto.resolution.ResolutionResponse;
import civicpulse_backend.dto.resolution.UpdateResolutionRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.ResolutionRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class ResolutionService {

    private final ResolutionRepository resolutionRepository;
    private final IssueRepository issueRepository;
    private final IssueStatusService statusService;
    private final NotificationService notificationService;
    private final SecurityUtils securityUtils;

    public ResolutionService(ResolutionRepository resolutionRepository,
                             IssueRepository issueRepository,
                             IssueStatusService statusService,
                             NotificationService notificationService,
                             SecurityUtils securityUtils) {
        this.resolutionRepository = resolutionRepository;
        this.issueRepository = issueRepository;
        this.statusService = statusService;
        this.notificationService = notificationService;
        this.securityUtils = securityUtils;
    }

    @Transactional
    public ResolutionResponse createResolution(Long issueId, CreateResolutionRequest request) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + issueId));

        User currentUser = securityUtils.getCurrentUser();
        if (currentUser.getRole() != Role.ADMIN && currentUser.getRole() != Role.OFFICIAL) {
            throw new UnauthorizedOperationException("Only officials and administrators can resolve issues");
        }

        if (resolutionRepository.existsByIssue_IssueId(issueId)) {
            throw new ConflictException("A resolution already exists for issue id: " + issueId);
        }

        Resolution resolution = new Resolution();
        resolution.setResolutionDescription(request.getResolutionDescription().trim());
        resolution.setResolutionImage(request.getResolutionImage());
        resolution.setIssue(issue);
        resolution.setResolvedBy(currentUser);
        resolution.setResolvedAt(LocalDateTime.now());

        Resolution saved = resolutionRepository.save(resolution);

        // Update issue status to RESOLVED
        IssueStatus resolvedStatus = statusService.getOrCreateStatus("RESOLVED", "Issue has been resolved");
        issue.setStatus(resolvedStatus);
        issue.setUpdatedAt(LocalDateTime.now());
        issueRepository.save(issue);

        // Send notification to issue owner
        notificationService.createNotification(
                issue.getUser(),
                issue,
                "Issue Resolved",
                "Your issue '" + issue.getTitle() + "' has been marked as resolved.",
                NotificationType.ISSUE_RESOLVED
        );

        return ResolutionResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public ResolutionResponse getResolutionForIssue(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        Resolution resolution = resolutionRepository.findByIssue_IssueId(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Resolution not found for issue id: " + issueId));
        return ResolutionResponse.fromEntity(resolution);
    }

    @Transactional
    public ResolutionResponse updateResolution(Long resolutionId, UpdateResolutionRequest request) {
        Resolution resolution = resolutionRepository.findById(resolutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Resolution not found with id: " + resolutionId));

        User currentUser = securityUtils.getCurrentUser();
        if (currentUser.getRole() != Role.ADMIN && currentUser.getRole() != Role.OFFICIAL) {
            throw new UnauthorizedOperationException("Only officials and administrators can modify resolutions");
        }

        if (request.getResolutionDescription() != null) {
            resolution.setResolutionDescription(request.getResolutionDescription().trim());
        }
        if (request.getResolutionImage() != null) {
            resolution.setResolutionImage(request.getResolutionImage());
        }

        Resolution saved = resolutionRepository.save(resolution);
        return ResolutionResponse.fromEntity(saved);
    }
}
