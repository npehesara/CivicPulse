package civicpulse_backend.controller;

import civicpulse_backend.dto.resolution.CreateResolutionRequest;
import civicpulse_backend.dto.resolution.ResolutionResponse;
import civicpulse_backend.dto.resolution.UpdateResolutionRequest;
import civicpulse_backend.service.ResolutionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
public class ResolutionController {

    private final ResolutionService resolutionService;

    public ResolutionController(ResolutionService resolutionService) {
        this.resolutionService = resolutionService;
    }

    @PostMapping("/api/issues/{issueId}/resolution")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<ResolutionResponse> createResolution(@PathVariable Long issueId, @Valid @RequestBody CreateResolutionRequest request) {
        ResolutionResponse response = resolutionService.createResolution(issueId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/api/issues/{issueId}/resolution")
    public ResponseEntity<ResolutionResponse> getResolutionForIssue(@PathVariable Long issueId) {
        ResolutionResponse response = resolutionService.getResolutionForIssue(issueId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/api/resolutions/{resolutionId}")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<ResolutionResponse> updateResolution(@PathVariable Long resolutionId, @RequestBody UpdateResolutionRequest request) {
        ResolutionResponse response = resolutionService.updateResolution(resolutionId, request);
        return ResponseEntity.ok(response);
    }
}
