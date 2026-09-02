package civicpulse_backend.dto.upvote;

public class UpvoteCountResponse {

    private Long issueId;
    private long upvoteCount;

    public UpvoteCountResponse() {
    }

    public UpvoteCountResponse(Long issueId, long upvoteCount) {
        this.issueId = issueId;
        this.upvoteCount = upvoteCount;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }

    public long getUpvoteCount() {
        return upvoteCount;
    }

    public void setUpvoteCount(long upvoteCount) {
        this.upvoteCount = upvoteCount;
    }
}
