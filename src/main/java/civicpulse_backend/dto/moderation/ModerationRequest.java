package civicpulse_backend.dto.moderation;

import civicpulse_backend.entity.ModerationStatus;

public class ModerationRequest {

    private Double toxicityScore;
    private Double spamScore;
    private Boolean privacyDetected;
    private ModerationStatus textModerationStatus;

    public ModerationRequest() {
    }

    public Double getToxicityScore() {
        return toxicityScore;
    }

    public void setToxicityScore(Double toxicityScore) {
        this.toxicityScore = toxicityScore;
    }

    public Double getSpamScore() {
        return spamScore;
    }

    public void setSpamScore(Double spamScore) {
        this.spamScore = spamScore;
    }

    public Boolean getPrivacyDetected() {
        return privacyDetected;
    }

    public void setPrivacyDetected(Boolean privacyDetected) {
        this.privacyDetected = privacyDetected;
    }

    public ModerationStatus getTextModerationStatus() {
        return textModerationStatus;
    }

    public void setTextModerationStatus(ModerationStatus textModerationStatus) {
        this.textModerationStatus = textModerationStatus;
    }
}
