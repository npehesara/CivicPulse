package civicpulse_backend.controller;

import civicpulse_backend.dto.upvote.UpvoteCountResponse;
import civicpulse_backend.dto.upvote.UpvoteResponse;
import civicpulse_backend.dto.upvote.UpvoteStatusResponse;
import civicpulse_backend.service.UpvoteService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/issues/{issueId}/upvotes")
public class UpvoteController {

    private final UpvoteService upvoteService;

    public UpvoteController(UpvoteService upvoteService) {
        this.upvoteService = upvoteService;
    }

    @PostMapping
    public ResponseEntity<UpvoteResponse> addUpvote(@PathVariable Long issueId) {
        UpvoteResponse response = upvoteService.addUpvote(issueId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @DeleteMapping
    public ResponseEntity<UpvoteResponse> removeUpvote(@PathVariable Long issueId) {
        UpvoteResponse response = upvoteService.removeUpvote(issueId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/count")
    public ResponseEntity<UpvoteCountResponse> getUpvoteCount(@PathVariable Long issueId) {
        UpvoteCountResponse response = upvoteService.getUpvoteCount(issueId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UpvoteStatusResponse> getCurrentUserUpvoteStatus(@PathVariable Long issueId) {
        UpvoteStatusResponse response = upvoteService.getCurrentUserUpvoteStatus(issueId);
        return ResponseEntity.ok(response);
    }
}
