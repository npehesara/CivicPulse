package civicpulse_backend.service;

import civicpulse_backend.dto.comment.CommentResponse;
import civicpulse_backend.dto.comment.CreateCommentRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.CommentRepository;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CommentServiceTest {

    @Mock
    private CommentRepository commentRepository;
    @Mock
    private IssueRepository issueRepository;
    @Mock
    private NotificationService notificationService;
    @Mock
    private SecurityUtils securityUtils;

    @InjectMocks
    private CommentService commentService;

    private User issueOwner;
    private User commenter;
    private User thirdParty;
    private Issue issue;
    private Comment comment;

    @BeforeEach
    void setUp() {
        issueOwner = new User("Owner", "owner@example.com", "hash", "0111111111", Role.CITIZEN, AccountStatus.ACTIVE);
        issueOwner.setUserId(1L);

        commenter = new User("Commenter", "commenter@example.com", "hash", "0222222222", Role.CITIZEN, AccountStatus.ACTIVE);
        commenter.setUserId(2L);

        thirdParty = new User("Third Party", "third@example.com", "hash", "0333333333", Role.CITIZEN, AccountStatus.ACTIVE);
        thirdParty.setUserId(3L);

        issue = new Issue();
        issue.setIssueId(1L);
        issue.setTitle("Damaged Bridge");
        issue.setUser(issueOwner);

        comment = new Comment("I noticed this too!", issue, commenter);
        comment.setCommentId(10L);
        comment.setCreatedAt(LocalDateTime.now());
        comment.setIsDeleted(false);
    }

    @Test
    void shouldAddCommentAndSendNotification() {
        CreateCommentRequest request = new CreateCommentRequest("I noticed this too!");
        when(issueRepository.findById(1L)).thenReturn(Optional.of(issue));
        when(securityUtils.getCurrentUser()).thenReturn(commenter);
        when(commentRepository.save(any(Comment.class))).thenReturn(comment);

        CommentResponse response = commentService.addComment(1L, request);
        assertNotNull(response);
        assertEquals("I noticed this too!", response.getCommentText());
        verify(notificationService).createNotification(eq(issueOwner), eq(issue), anyString(), anyString(), eq(NotificationType.COMMENT_ADDED));
    }

    @Test
    void shouldGetCommentsForIssue() {
        when(issueRepository.existsById(1L)).thenReturn(true);
        when(commentRepository.findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(1L)).thenReturn(List.of(comment));

        List<CommentResponse> list = commentService.getCommentsForIssue(1L);
        assertEquals(1, list.size());
    }

    @Test
    void shouldAllowCommenterToDeleteOwnComment() {
        when(commentRepository.findById(10L)).thenReturn(Optional.of(comment));
        when(securityUtils.getCurrentUser()).thenReturn(commenter);

        commentService.deleteComment(10L);

        assertTrue(comment.getIsDeleted());
        verify(commentRepository).save(comment);
    }

    @Test
    void shouldPreventUnauthorizedUserFromDeletingComment() {
        when(commentRepository.findById(10L)).thenReturn(Optional.of(comment));
        when(securityUtils.getCurrentUser()).thenReturn(thirdParty);

        assertThrows(UnauthorizedOperationException.class, () -> commentService.deleteComment(10L));
    }
}
