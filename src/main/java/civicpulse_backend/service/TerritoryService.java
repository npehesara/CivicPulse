package civicpulse_backend.service;

import civicpulse_backend.dto.territory.TerritoryRequest;
import civicpulse_backend.dto.territory.TerritoryResponse;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.TerritoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class TerritoryService {

    private final TerritoryRepository territoryRepository;

    public TerritoryService(TerritoryRepository territoryRepository) {
        this.territoryRepository = territoryRepository;
    }

    @Transactional
    public TerritoryResponse createTerritory(TerritoryRequest request) {
        Territory territory = new Territory();
        territory.setTerritoryName(request.getTerritoryName().trim());
        territory.setTerritoryType(request.getTerritoryType());
        territory.setBoundaryGeometry(request.getBoundaryGeometry());
        territory.setCreatedAt(LocalDateTime.now());

        if (request.getParentTerritoryId() != null) {
            Territory parent = territoryRepository.findById(request.getParentTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent territory not found with id: " + request.getParentTerritoryId()));
            territory.setParentTerritory(parent);
        }

        Territory saved = territoryRepository.save(territory);
        return TerritoryResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<TerritoryResponse> getAllTerritories() {
        return territoryRepository.findAll().stream()
                .map(TerritoryResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TerritoryResponse getTerritoryById(Long id) {
        Territory territory = territoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + id));
        return TerritoryResponse.fromEntity(territory);
    }

    @Transactional
    public TerritoryResponse updateTerritory(Long id, TerritoryRequest request) {
        Territory territory = territoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + id));

        territory.setTerritoryName(request.getTerritoryName().trim());
        territory.setTerritoryType(request.getTerritoryType());
        territory.setBoundaryGeometry(request.getBoundaryGeometry());

        if (request.getParentTerritoryId() != null) {
            if (request.getParentTerritoryId().equals(id)) {
                throw new IllegalArgumentException("Territory cannot be its own parent");
            }
            Territory parent = territoryRepository.findById(request.getParentTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent territory not found with id: " + request.getParentTerritoryId()));
            territory.setParentTerritory(parent);
        } else {
            territory.setParentTerritory(null);
        }

        Territory saved = territoryRepository.save(territory);
        return TerritoryResponse.fromEntity(saved);
    }

    @Transactional
    public void deleteTerritory(Long id) {
        if (!territoryRepository.existsById(id)) {
            throw new ResourceNotFoundException("Territory not found with id: " + id);
        }
        territoryRepository.deleteById(id);
    }
}
