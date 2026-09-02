package civicpulse_backend.dto.upvote;

public class UpvoteResponse {

    private String message;
    private Long issueId;
    private long totalUpvotes;

    public UpvoteResponse() {
    }

    public UpvoteResponse(String message, Long issueId, long totalUpvotes) {
        this.message = message;
        this.issueId = issueId;
        this.totalUpvotes = totalUpvotes;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }

    public long getTotalUpvotes() {
        return totalUpvotes;
    }

    public void setTotalUpvotes(long totalUpvotes) {
        this.totalUpvotes = totalUpvotes;
    }
}
