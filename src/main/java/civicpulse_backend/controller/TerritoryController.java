package civicpulse_backend.controller;

import civicpulse_backend.dto.territory.TerritoryRequest;
import civicpulse_backend.dto.territory.TerritoryResponse;
import civicpulse_backend.service.TerritoryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/territories")
public class TerritoryController {

    private final TerritoryService territoryService;

    public TerritoryController(TerritoryService territoryService) {
        this.territoryService = territoryService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<TerritoryResponse> createTerritory(@Valid @RequestBody TerritoryRequest request) {
        TerritoryResponse response = territoryService.createTerritory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<TerritoryResponse>> getAllTerritories() {
        List<TerritoryResponse> response = territoryService.getAllTerritories();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TerritoryResponse> getTerritoryById(@PathVariable Long id) {
        TerritoryResponse response = territoryService.getTerritoryById(id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<TerritoryResponse> updateTerritory(@PathVariable Long id, @Valid @RequestBody TerritoryRequest request) {
        TerritoryResponse response = territoryService.updateTerritory(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteTerritory(@PathVariable Long id) {
        territoryService.deleteTerritory(id);
        return ResponseEntity.noContent().build();
    }
}
