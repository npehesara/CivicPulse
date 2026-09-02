package civicpulse_backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "resolutions")
public class Resolution {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "resolution_id")
    private Long resolutionId;

    @Column(name = "resolution_description", nullable = false, columnDefinition = "TEXT")
    private String resolutionDescription;

    @Column(name = "resolution_image")
    private String resolutionImage;

    @Column(name = "resolved_at", nullable = false, updatable = false)
    private LocalDateTime resolvedAt;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issue_id", unique = true, nullable = false)
    private Issue issue;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by", nullable = false)
    private User resolvedBy;

    public Resolution() {
    }

    public Resolution(String resolutionDescription, String resolutionImage, Issue issue, User resolvedBy) {
        this.resolutionDescription = resolutionDescription;
        this.resolutionImage = resolutionImage;
        this.issue = issue;
        this.resolvedBy = resolvedBy;
    }

    @PrePersist
    protected void onCreate() {
        if (this.resolvedAt == null) {
            this.resolvedAt = LocalDateTime.now();
        }
    }

    // Getters and Setters

    public Long getResolutionId() {
        return resolutionId;
    }

    public void setResolutionId(Long resolutionId) {
        this.resolutionId = resolutionId;
    }

    public String getResolutionDescription() {
        return resolutionDescription;
    }

    public void setResolutionDescription(String resolutionDescription) {
        this.resolutionDescription = resolutionDescription;
    }

    public String getResolutionImage() {
        return resolutionImage;
    }

    public void setResolutionImage(String resolutionImage) {
        this.resolutionImage = resolutionImage;
    }

    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }

    public void setResolvedAt(LocalDateTime resolvedAt) {
        this.resolvedAt = resolvedAt;
    }

    public Issue getIssue() {
        return issue;
    }

    public void setIssue(Issue issue) {
        this.issue = issue;
    }

    public User getResolvedBy() {
        return resolvedBy;
    }

    public void setResolvedBy(User resolvedBy) {
        this.resolvedBy = resolvedBy;
    }
}
