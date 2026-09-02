package civicpulse_backend.dto.department;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class DepartmentRequest {

    @NotBlank(message = "Department name is required")
    private String departmentName;

    private String description;

    private String contactNumber;

    @Email(message = "Invalid email format")
    private String email;

    private Long territoryId;

    public DepartmentRequest() {
    }

    public DepartmentRequest(String departmentName, String description, String contactNumber, String email, Long territoryId) {
        this.departmentName = departmentName;
        this.description = description;
        this.contactNumber = contactNumber;
        this.email = email;
        this.territoryId = territoryId;
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
}
