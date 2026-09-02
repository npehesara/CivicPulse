package civicpulse_backend.dto.territory;

import jakarta.validation.constraints.NotBlank;

public class TerritoryRequest {

    @NotBlank(message = "Territory name is required")
    private String territoryName;

    private String territoryType;

    private Long parentTerritoryId;

    private String boundaryGeometry;

    public TerritoryRequest() {
    }

    public TerritoryRequest(String territoryName, String territoryType, Long parentTerritoryId, String boundaryGeometry) {
        this.territoryName = territoryName;
        this.territoryType = territoryType;
        this.parentTerritoryId = parentTerritoryId;
        this.boundaryGeometry = boundaryGeometry;
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

    public String getBoundaryGeometry() {
        return boundaryGeometry;
    }

    public void setBoundaryGeometry(String boundaryGeometry) {
        this.boundaryGeometry = boundaryGeometry;
    }
}
