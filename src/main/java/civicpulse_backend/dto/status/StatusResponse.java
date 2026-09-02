package civicpulse_backend.dto.status;

import civicpulse_backend.entity.IssueStatus;

public class StatusResponse {

    private Long statusId;
    private String statusName;
    private String description;

    public StatusResponse() {
    }

    public static StatusResponse fromEntity(IssueStatus status) {
        if (status == null) return null;
        StatusResponse response = new StatusResponse();
        response.setStatusId(status.getStatusId());
        response.setStatusName(status.getStatusName());
        response.setDescription(status.getDescription());
        return response;
    }

    public Long getStatusId() {
        return statusId;
    }

    public void setStatusId(Long statusId) {
        this.statusId = statusId;
    }

    public String getStatusName() {
        return statusName;
    }

    public void setStatusName(String statusName) {
        this.statusName = statusName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
