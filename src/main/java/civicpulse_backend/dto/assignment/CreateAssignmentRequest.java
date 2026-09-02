package civicpulse_backend.dto.assignment;

import jakarta.validation.constraints.NotNull;

public class CreateAssignmentRequest {

    @NotNull(message = "Department ID is required")
    private Long departmentId;

    private Long assignedUserId;

    public CreateAssignmentRequest() {
    }

    public CreateAssignmentRequest(Long departmentId, Long assignedUserId) {
        this.departmentId = departmentId;
        this.assignedUserId = assignedUserId;
    }

    public Long getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Long departmentId) {
        this.departmentId = departmentId;
    }

    public Long getAssignedUserId() {
        return assignedUserId;
    }

    public void setAssignedUserId(Long assignedUserId) {
        this.assignedUserId = assignedUserId;
    }
}
