package civicpulse_backend.service;

import civicpulse_backend.dto.territory.TerritoryRequest;
import civicpulse_backend.dto.territory.TerritoryResponse;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.TerritoryRepository;
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
class TerritoryServiceTest {

    @Mock
    private TerritoryRepository territoryRepository;

    @InjectMocks
    private TerritoryService territoryService;

    private Territory territory;

    @BeforeEach
    void setUp() {
        territory = new Territory("Colombo Municipality", "MUNICIPALITY", null, "{\"type\": \"Polygon\"}");
        territory.setTerritoryId(1L);
        territory.setCreatedAt(LocalDateTime.now());
    }

    @Test
    void shouldCreateTerritorySuccessfully() {
        TerritoryRequest request = new TerritoryRequest("Colombo Municipality", "MUNICIPALITY", null, "{\"type\": \"Polygon\"}");
        when(territoryRepository.save(any(Territory.class))).thenReturn(territory);

        TerritoryResponse response = territoryService.createTerritory(request);
        assertNotNull(response);
        assertEquals("Colombo Municipality", response.getTerritoryName());
    }

    @Test
    void shouldGetTerritoryById() {
        when(territoryRepository.findById(1L)).thenReturn(Optional.of(territory));

        TerritoryResponse response = territoryService.getTerritoryById(1L);
        assertNotNull(response);
        assertEquals(1L, response.getTerritoryId());
    }

    @Test
    void shouldGetAllTerritories() {
        when(territoryRepository.findAll()).thenReturn(List.of(territory));

        List<TerritoryResponse> list = territoryService.getAllTerritories();
        assertEquals(1, list.size());
    }

    @Test
    void shouldUpdateTerritory() {
        TerritoryRequest request = new TerritoryRequest("Updated Municipality", "MUNICIPALITY", null, null);
        when(territoryRepository.findById(1L)).thenReturn(Optional.of(territory));
        when(territoryRepository.save(any(Territory.class))).thenReturn(territory);

        TerritoryResponse response = territoryService.updateTerritory(1L, request);
        assertNotNull(response);
    }

    @Test
    void shouldDeleteTerritory() {
        when(territoryRepository.existsById(1L)).thenReturn(true);

        territoryService.deleteTerritory(1L);
        verify(territoryRepository).deleteById(1L);
    }
}
