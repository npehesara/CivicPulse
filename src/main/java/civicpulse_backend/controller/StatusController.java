package civicpulse_backend.controller;

import civicpulse_backend.dto.status.StatusRequest;
import civicpulse_backend.dto.status.StatusResponse;
import civicpulse_backend.service.IssueStatusService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/statuses")
public class StatusController {

    private final IssueStatusService statusService;

    public StatusController(IssueStatusService statusService) {
        this.statusService = statusService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<StatusResponse> createStatus(@Valid @RequestBody StatusRequest request) {
        StatusResponse response = statusService.createStatus(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<StatusResponse>> getAllStatuses() {
        List<StatusResponse> response = statusService.getAllStatuses();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<StatusResponse> getStatusById(@PathVariable Long id) {
        StatusResponse response = statusService.getStatusById(id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<StatusResponse> updateStatus(@PathVariable Long id, @Valid @RequestBody StatusRequest request) {
        StatusResponse response = statusService.updateStatus(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteStatus(@PathVariable Long id) {
        statusService.deleteStatus(id);
        return ResponseEntity.noContent().build();
    }
}
