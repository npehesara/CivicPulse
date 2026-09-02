package civicpulse_backend.service;

import civicpulse_backend.dto.upvote.UpvoteCountResponse;
import civicpulse_backend.dto.upvote.UpvoteResponse;
import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.Upvote;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.repository.UpvoteRepository;
import civicpulse_backend.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UpvoteServiceTest {

    @Mock
    private UpvoteRepository upvoteRepository;
    @Mock
    private IssueRepository issueRepository;
    @Mock
    private SecurityUtils securityUtils;

    @InjectMocks
    private UpvoteService upvoteService;

    private User user;
    private Issue issue;
    private Upvote upvote;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setUserId(1L);

        issue = new Issue();
        issue.setIssueId(1L);

        upvote = new Upvote(issue, user);
        upvote.setUpvoteId(1L);
    }

    @Test
    void shouldAddUpvoteSuccessfully() {
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(upvoteRepository.existsByIssue_IssueIdAndUser_UserId(1L, 1L)).thenReturn(false);
        when(upvoteRepository.countByIssue_IssueId(1L)).thenReturn(1L);

        UpvoteResponse response = upvoteService.addUpvote(1L);
        assertNotNull(response);
        assertEquals(1L, response.getTotalUpvotes());
        verify(upvoteRepository).save(any(Upvote.class));
    }

    @Test
    void shouldPreventDuplicateUpvote() {
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(upvoteRepository.existsByIssue_IssueIdAndUser_UserId(1L, 1L)).thenReturn(true);

        assertThrows(ConflictException.class, () -> upvoteService.addUpvote(1L));
        verify(upvoteRepository, never()).save(any(Upvote.class));
    }

    @Test
    void shouldRemoveUpvoteSuccessfully() {
        when(issueRepository.existsById(1L)).thenReturn(true);
        when(securityUtils.getCurrentUser()).thenReturn(user);
        when(upvoteRepository.findByIssue_IssueIdAndUser_UserId(1L, 1L)).thenReturn(Optional.of(upvote));
        when(upvoteRepository.countByIssue_IssueId(1L)).thenReturn(0L);

        UpvoteResponse response = upvoteService.removeUpvote(1L);
        assertNotNull(response);
        assertEquals(0L, response.getTotalUpvotes());
        verify(upvoteRepository).delete(upvote);
    }

    @Test
    void shouldGetUpvoteCount() {
        when(issueRepository.existsById(1L)).thenReturn(true);
        when(upvoteRepository.countByIssue_IssueId(1L)).thenReturn(42L);

        UpvoteCountResponse response = upvoteService.getUpvoteCount(1L);
        assertEquals(42L, response.getUpvoteCount());
    }
}
