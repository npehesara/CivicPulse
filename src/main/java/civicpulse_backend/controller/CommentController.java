package civicpulse_backend.controller;

import civicpulse_backend.dto.comment.CreateCommentRequest;
import civicpulse_backend.dto.comment.CommentResponse;
import civicpulse_backend.service.CommentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class CommentController {

    private final CommentService commentService;

    public CommentController(CommentService commentService) {
        this.commentService = commentService;
    }

    @PostMapping("/api/issues/{issueId}/comments")
    public ResponseEntity<CommentResponse> addComment(@PathVariable Long issueId, @Valid @RequestBody CreateCommentRequest request) {
        CommentResponse response = commentService.addComment(issueId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/api/issues/{issueId}/comments")
    public ResponseEntity<List<CommentResponse>> getCommentsForIssue(@PathVariable Long issueId) {
        List<CommentResponse> response = commentService.getCommentsForIssue(issueId);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/api/comments/{commentId}")
    public ResponseEntity<Void> deleteComment(@PathVariable Long commentId) {
        commentService.deleteComment(commentId);
        return ResponseEntity.noContent().build();
    }
}
