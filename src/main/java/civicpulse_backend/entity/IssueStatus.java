package civicpulse_backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "issue_statuses")
public class IssueStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "status_id")
    private Long statusId;

    @Column(name = "status_name", unique = true, nullable = false)
    private String statusName;

    @Column(columnDefinition = "TEXT")
    private String description;

    public IssueStatus() {
    }

    public IssueStatus(String statusName, String description) {
        this.statusName = statusName;
        this.description = description;
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
