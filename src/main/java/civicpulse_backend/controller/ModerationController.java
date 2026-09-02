package civicpulse_backend.controller;

import civicpulse_backend.dto.moderation.ModerationRequest;
import civicpulse_backend.dto.moderation.ModerationResponse;
import civicpulse_backend.service.ModerationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
public class ModerationController {

    private final ModerationService moderationService;

    public ModerationController(ModerationService moderationService) {
        this.moderationService = moderationService;
    }

    @GetMapping("/api/issues/{issueId}/moderation")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<ModerationResponse> getModerationForIssue(@PathVariable Long issueId) {
        ModerationResponse response = moderationService.getModerationForIssue(issueId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/api/issues/{issueId}/moderation")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<ModerationResponse> createOrUpdateModerationForIssue(@PathVariable Long issueId, @RequestBody ModerationRequest request) {
        ModerationResponse response = moderationService.createOrUpdateModerationForIssue(issueId, request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/api/moderation/{moderationId}")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<ModerationResponse> updateModerationById(@PathVariable Long moderationId, @RequestBody ModerationRequest request) {
        ModerationResponse response = moderationService.updateModerationById(moderationId, request);
        return ResponseEntity.ok(response);
    }
}
