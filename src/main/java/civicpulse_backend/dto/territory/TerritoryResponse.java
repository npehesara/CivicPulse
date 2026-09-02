package civicpulse_backend.dto.territory;

import civicpulse_backend.entity.Territory;
import java.time.LocalDateTime;

public class TerritoryResponse {

    private Long territoryId;
    private String territoryName;
    private String territoryType;
    private Long parentTerritoryId;
    private String parentTerritoryName;
    private String boundaryGeometry;
    private LocalDateTime createdAt;

    public TerritoryResponse() {
    }

    public static TerritoryResponse fromEntity(Territory territory) {
        if (territory == null) return null;
        TerritoryResponse response = new TerritoryResponse();
        response.setTerritoryId(territory.getTerritoryId());
        response.setTerritoryName(territory.getTerritoryName());
        response.setTerritoryType(territory.getTerritoryType());
        if (territory.getParentTerritory() != null) {
            response.setParentTerritoryId(territory.getParentTerritory().getTerritoryId());
            response.setParentTerritoryName(territory.getParentTerritory().getTerritoryName());
        }
        response.setBoundaryGeometry(territory.getBoundaryGeometry());
        response.setCreatedAt(territory.getCreatedAt());
        return response;
    }

    public Long getTerritoryId() {
        return territoryId;
    }

    public void setTerritoryId(Long territoryId) {
        this.territoryId = territoryId;
    }

    public String getTerritoryName() {
        return territoryName;
    }

    public void setTerritoryName(String territoryName) {
        this.territoryName = territoryName;
    }

    public String getTerritoryType() {
        return territoryType;
    }

    public void setTerritoryType(String territoryType) {
        this.territoryType = territoryType;
    }

    public Long getParentTerritoryId() {
        return parentTerritoryId;
    }

    public void setParentTerritoryId(Long parentTerritoryId) {
        this.parentTerritoryId = parentTerritoryId;
    }

    public String getParentTerritoryName() {
        return parentTerritoryName;
    }

    public void setParentTerritoryName(String parentTerritoryName) {
        this.parentTerritoryName = parentTerritoryName;
    }

    public String getBoundaryGeometry() {
        return boundaryGeometry;
    }

    public void setBoundaryGeometry(String boundaryGeometry) {
        this.boundaryGeometry = boundaryGeometry;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
