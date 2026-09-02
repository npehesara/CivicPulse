package civicpulse_backend.service;

import civicpulse_backend.dto.upvote.UpvoteCountResponse;
import civicpulse_backend.dto.upvote.UpvoteResponse;
import civicpulse_backend.dto.upvote.UpvoteStatusResponse;
import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.Upvote;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.UpvoteRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class UpvoteService {

    private final UpvoteRepository upvoteRepository;
    private final IssueRepository issueRepository;
    private final SecurityUtils securityUtils;

    public UpvoteService(UpvoteRepository upvoteRepository,
                         IssueRepository issueRepository,
                         SecurityUtils securityUtils) {
        this.upvoteRepository = upvoteRepository;
        this.issueRepository = issueRepository;
        this.securityUtils = securityUtils;
    }

    @Transactional
    public UpvoteResponse addUpvote(Long issueId) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + issueId));

        User currentUser = securityUtils.getCurrentUser();

        if (upvoteRepository.existsByIssue_IssueIdAndUser_UserId(issueId, currentUser.getUserId())) {
            throw new ConflictException("You have already upvoted this issue");
        }

        Upvote upvote = new Upvote();
        upvote.setIssue(issue);
        upvote.setUser(currentUser);
        upvote.setCreatedAt(LocalDateTime.now());

        upvoteRepository.save(upvote);
        long count = upvoteRepository.countByIssue_IssueId(issueId);

        return new UpvoteResponse("Upvote recorded successfully", issueId, count);
    }

    @Transactional
    public UpvoteResponse removeUpvote(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }

        User currentUser = securityUtils.getCurrentUser();
        Upvote upvote = upvoteRepository.findByIssue_IssueIdAndUser_UserId(issueId, currentUser.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Upvote not found for current user on issue " + issueId));

        upvoteRepository.delete(upvote);
        long count = upvoteRepository.countByIssue_IssueId(issueId);

        return new UpvoteResponse("Upvote removed successfully", issueId, count);
    }

    @Transactional(readOnly = true)
    public UpvoteCountResponse getUpvoteCount(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        long count = upvoteRepository.countByIssue_IssueId(issueId);
        return new UpvoteCountResponse(issueId, count);
    }

    @Transactional(readOnly = true)
    public UpvoteStatusResponse getCurrentUserUpvoteStatus(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        User currentUser = securityUtils.getCurrentUser();
        boolean hasUpvoted = upvoteRepository.existsByIssue_IssueIdAndUser_UserId(issueId, currentUser.getUserId());
        return new UpvoteStatusResponse(issueId, hasUpvoted);
    }
}
