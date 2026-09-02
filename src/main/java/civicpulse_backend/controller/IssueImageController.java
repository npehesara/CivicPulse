package civicpulse_backend.controller;

import civicpulse_backend.dto.image.CreateImageRequest;
import civicpulse_backend.dto.image.ImageResponse;
import civicpulse_backend.service.IssueImageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/issues/{issueId}/images")
public class IssueImageController {

    private final IssueImageService imageService;

    public IssueImageController(IssueImageService imageService) {
        this.imageService = imageService;
    }

    @PostMapping
    public ResponseEntity<ImageResponse> addImageToIssue(@PathVariable Long issueId, @Valid @RequestBody CreateImageRequest request) {
        ImageResponse response = imageService.addImageToIssue(issueId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<ImageResponse>> getImagesForIssue(@PathVariable Long issueId) {
        List<ImageResponse> response = imageService.getImagesForIssue(issueId);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{imageId}")
    public ResponseEntity<Void> deleteImage(@PathVariable Long issueId, @PathVariable Long imageId) {
        imageService.deleteImage(issueId, imageId);
        return ResponseEntity.noContent().build();
    }
}
