package civicpulse_backend.controller;

import civicpulse_backend.dto.assignment.CreateAssignmentRequest;
import civicpulse_backend.dto.assignment.AssignmentResponse;
import civicpulse_backend.dto.assignment.UpdateAssignmentRequest;
import civicpulse_backend.service.IssueAssignmentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class AssignmentController {

    private final IssueAssignmentService assignmentService;

    public AssignmentController(IssueAssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @PostMapping("/api/issues/{issueId}/assignments")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<AssignmentResponse> createAssignment(@PathVariable Long issueId, @Valid @RequestBody CreateAssignmentRequest request) {
        AssignmentResponse response = assignmentService.createAssignment(issueId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/api/issues/{issueId}/assignments")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<List<AssignmentResponse>> getAssignmentsForIssue(@PathVariable Long issueId) {
        List<AssignmentResponse> response = assignmentService.getAssignmentsForIssue(issueId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/api/assignments/{assignmentId}")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<AssignmentResponse> updateAssignment(@PathVariable Long assignmentId, @RequestBody UpdateAssignmentRequest request) {
        AssignmentResponse response = assignmentService.updateAssignment(assignmentId, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/api/assignments/{assignmentId}")
    @PreAuthorize("hasAnyRole('OFFICIAL', 'ADMIN')")
    public ResponseEntity<Void> deleteAssignment(@PathVariable Long assignmentId) {
        assignmentService.deleteAssignment(assignmentId);
        return ResponseEntity.noContent().build();
    }
}
