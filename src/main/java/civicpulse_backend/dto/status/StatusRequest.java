package civicpulse_backend.dto.status;

import jakarta.validation.constraints.NotBlank;

public class StatusRequest {

    @NotBlank(message = "Status name is required")
    private String statusName;

    private String description;

    public StatusRequest() {
    }

    public StatusRequest(String statusName, String description) {
        this.statusName = statusName;
        this.description = description;
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
