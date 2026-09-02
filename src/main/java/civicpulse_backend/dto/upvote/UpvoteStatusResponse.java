package civicpulse_backend.dto.upvote;

public class UpvoteStatusResponse {

    private Long issueId;
    private boolean hasUpvoted;

    public UpvoteStatusResponse() {
    }

    public UpvoteStatusResponse(Long issueId, boolean hasUpvoted) {
        this.issueId = issueId;
        this.hasUpvoted = hasUpvoted;
    }

    public Long getIssueId() {
        return issueId;
    }

    public void setIssueId(Long issueId) {
        this.issueId = issueId;
    }

    public boolean isHasUpvoted() {
        return hasUpvoted;
    }

    public void setHasUpvoted(boolean hasUpvoted) {
        this.hasUpvoted = hasUpvoted;
    }
}
