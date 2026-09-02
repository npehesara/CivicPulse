package civicpulse_backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "territories")
public class Territory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "territory_id")
    private Long territoryId;

    @Column(name = "territory_name", nullable = false)
    private String territoryName;

    @Column(name = "territory_type")
    private String territoryType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_territory_id")
    private Territory parentTerritory;

    @Column(name = "boundary_geometry", columnDefinition = "TEXT")
    private String boundaryGeometry;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public Territory() {
    }

    public Territory(String territoryName, String territoryType, Territory parentTerritory, String boundaryGeometry) {
        this.territoryName = territoryName;
        this.territoryType = territoryType;
        this.parentTerritory = parentTerritory;
        this.boundaryGeometry = boundaryGeometry;
    }

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
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

    public Territory getParentTerritory() {
        return parentTerritory;
    }

    public void setParentTerritory(Territory parentTerritory) {
        this.parentTerritory = parentTerritory;
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
