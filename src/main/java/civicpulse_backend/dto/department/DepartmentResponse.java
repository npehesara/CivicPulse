package civicpulse_backend.dto.department;

import civicpulse_backend.entity.Department;

public class DepartmentResponse {

    private Long departmentId;
    private String departmentName;
    private String description;
    private String contactNumber;
    private String email;
    private Long territoryId;
    private String territoryName;

    public DepartmentResponse() {
    }

    public static DepartmentResponse fromEntity(Department department) {
        if (department == null) return null;
        DepartmentResponse response = new DepartmentResponse();
        response.setDepartmentId(department.getDepartmentId());
        response.setDepartmentName(department.getDepartmentName());
        response.setDescription(department.getDescription());
        response.setContactNumber(department.getContactNumber());
        response.setEmail(department.getEmail());
        if (department.getTerritory() != null) {
            response.setTerritoryId(department.getTerritory().getTerritoryId());
            response.setTerritoryName(department.getTerritory().getTerritoryName());
        }
        return response;
    }

    public Long getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Long departmentId) {
        this.departmentId = departmentId;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getContactNumber() {
        return contactNumber;
    }

    public void setContactNumber(String contactNumber) {
        this.contactNumber = contactNumber;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
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
}
