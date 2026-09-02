package civicpulse_backend.dto.assignment;

public class UpdateAssignmentRequest {

    private Long departmentId;
    private Long assignedUserId;
    private Boolean markCompleted;

    public UpdateAssignmentRequest() {
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

    public Boolean getMarkCompleted() {
        return markCompleted;
    }

    public void setMarkCompleted(Boolean markCompleted) {
        this.markCompleted = markCompleted;
    }
}
