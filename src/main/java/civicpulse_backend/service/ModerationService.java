package civicpulse_backend.service;

import civicpulse_backend.dto.moderation.ModerationRequest;
import civicpulse_backend.dto.moderation.ModerationResponse;
import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.Moderation;
import civicpulse_backend.entity.ModerationStatus;
import civicpulse_backend.entity.NotificationType;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.ModerationRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class ModerationService {

    private final ModerationRepository moderationRepository;
    private final IssueRepository issueRepository;
    private final NotificationService notificationService;
    private final SecurityUtils securityUtils;

    public ModerationService(ModerationRepository moderationRepository,
                             IssueRepository issueRepository,
                             NotificationService notificationService,
                             SecurityUtils securityUtils) {
        this.moderationRepository = moderationRepository;
        this.issueRepository = issueRepository;
        this.notificationService = notificationService;
        this.securityUtils = securityUtils;
    }

    @Transactional(readOnly = true)
    public ModerationResponse getModerationForIssue(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        Moderation moderation = moderationRepository.findByIssue_IssueId(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Moderation record not found for issue id: " + issueId));
        return ModerationResponse.fromEntity(moderation);
    }

    @Transactional
    public ModerationResponse createOrUpdateModerationForIssue(Long issueId, ModerationRequest request) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + issueId));

        Moderation moderation = moderationRepository.findByIssue_IssueId(issueId)
                .orElseGet(() -> {
                    Moderation m = new Moderation();
                    m.setIssue(issue);
                    m.setCreatedAt(LocalDateTime.now());
                    return m;
                });

        if (request.getToxicityScore() != null) moderation.setToxicityScore(request.getToxicityScore());
        if (request.getSpamScore() != null) moderation.setSpamScore(request.getSpamScore());
        if (request.getPrivacyDetected() != null) moderation.setPrivacyDetected(request.getPrivacyDetected());
        if (request.getTextModerationStatus() != null) moderation.setTextModerationStatus(request.getTextModerationStatus());

        User currentUser = securityUtils.getCurrentUser();
        moderation.setReviewedBy(currentUser.getUserId());
        moderation.setReviewedAt(LocalDateTime.now());

        Moderation saved = moderationRepository.save(moderation);

        if (saved.getTextModerationStatus() == ModerationStatus.FLAGGED || saved.getTextModerationStatus() == ModerationStatus.REJECTED) {
            notificationService.createNotification(
                    issue.getUser(),
                    issue,
                    "Moderation Notice",
                    "Your issue '" + issue.getTitle() + "' moderation status is " + saved.getTextModerationStatus().name(),
                    NotificationType.MODERATION_ALERT
            );
        }

        return ModerationResponse.fromEntity(saved);
    }

    @Transactional
    public ModerationResponse updateModerationById(Long moderationId, ModerationRequest request) {
        Moderation moderation = moderationRepository.findById(moderationId)
                .orElseThrow(() -> new ResourceNotFoundException("Moderation not found with id: " + moderationId));

        if (request.getToxicityScore() != null) moderation.setToxicityScore(request.getToxicityScore());
        if (request.getSpamScore() != null) moderation.setSpamScore(request.getSpamScore());
        if (request.getPrivacyDetected() != null) moderation.setPrivacyDetected(request.getPrivacyDetected());
        if (request.getTextModerationStatus() != null) moderation.setTextModerationStatus(request.getTextModerationStatus());

        User currentUser = securityUtils.getCurrentUser();
        moderation.setReviewedBy(currentUser.getUserId());
        moderation.setReviewedAt(LocalDateTime.now());

        Moderation saved = moderationRepository.save(moderation);
        return ModerationResponse.fromEntity(saved);
    }
}
