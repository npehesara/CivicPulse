package civicpulse_backend.repository;

import civicpulse_backend.entity.Territory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TerritoryRepository extends JpaRepository<Territory, Long> {
    List<Territory> findByParentTerritory_TerritoryId(Long parentTerritoryId);
}
