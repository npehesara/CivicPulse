package civicpulse_backend.dto.assignment;

import civicpulse_backend.entity.IssueAssignment;
import java.time.LocalDateTime;

public class AssignmentResponse {

    private Long assignmentId;
    private Long issueId;
    private Long departmentId;
    private String departmentName;
    private Long assignedUserId;
    private String assignedUserFullName;
    private String assignedUserEmail;
    private LocalDateTime assignedAt;
    private LocalDateTime completedAt;

    public AssignmentResponse() {
    }

    public static AssignmentResponse fromEntity(IssueAssignment assignment) {
        if (assignment == null) return null;
        AssignmentResponse response = new AssignmentResponse();
        response.setAssignmentId(assignment.getAssignmentId());
        if (assignment.getIssue() != null) {
            response.setIssueId(assignment.getIssue().getIssueId());
        }
        if (assignment.getDepartment() != null) {
            response.setDepartmentId(assignment.getDepartment().getDepartmentId());
            response.setDepartmentName(assignment.getDepartment().getDepartmentName());
        }
        if (assignment.getAssignedUser() != null) {
            response.setAssignedUserId(assignment.getAssignedUser().getUserId());
            response.setAssignedUserFullName(assignment.getAssignedUser().getFullName());
            response.setAssignedUserEmail(assignment.getAssignedUser().getEmail());
        }
        response.setAssignedAt(assignment.getAssignedAt());
        response.setCompletedAt(assignment.getCompletedAt());
        return response;
    }

    public Long getAssignmentId() {
        return assignmentId;
    }

    public void setAssignmentId(Long assignmentId) {
        this.assignmentId = assignmentId;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
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

    public Long getAssignedUserId() {
        return assignedUserId;
    }

    public void setAssignedUserId(Long assignedUserId) {
        this.assignedUserId = assignedUserId;
    }

    public String getAssignedUserFullName() {
        return assignedUserFullName;
    }

    public void setAssignedUserFullName(String assignedUserFullName) {
        this.assignedUserFullName = assignedUserFullName;
    }

    public String getAssignedUserEmail() {
        return assignedUserEmail;
    }

    public void setAssignedUserEmail(String assignedUserEmail) {
        this.assignedUserEmail = assignedUserEmail;
    }

    public LocalDateTime getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(LocalDateTime assignedAt) {
        this.assignedAt = assignedAt;
    }

    public LocalDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(LocalDateTime completedAt) {
        this.completedAt = completedAt;
    }
}
