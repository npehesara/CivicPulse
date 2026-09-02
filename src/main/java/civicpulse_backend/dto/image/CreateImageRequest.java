package civicpulse_backend.dto.image;

import jakarta.validation.constraints.NotBlank;

public class CreateImageRequest {

    @NotBlank(message = "Image URL is required")
    private String imageUrl;

    private String originalFilename;

    private Double aiSafetyScore;

    private Double aiRelevanceScore;

    private Boolean isAnonymized;

    public CreateImageRequest() {
    }

    public CreateImageRequest(String imageUrl, String originalFilename) {
        this.imageUrl = imageUrl;
        this.originalFilename = originalFilename;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getOriginalFilename() {
        return originalFilename;
    }

    public void setOriginalFilename(String originalFilename) {
        this.originalFilename = originalFilename;
    }

    public Double getAiSafetyScore() {
        return aiSafetyScore;
    }

    public void setAiSafetyScore(Double aiSafetyScore) {
        this.aiSafetyScore = aiSafetyScore;
    }

    public Double getAiRelevanceScore() {
        return aiRelevanceScore;
    }

    public void setAiRelevanceScore(Double aiRelevanceScore) {
        this.aiRelevanceScore = aiRelevanceScore;
    }

    public Boolean getIsAnonymized() {
        return isAnonymized;
    }

    public void setIsAnonymized(Boolean isAnonymized) {
        this.isAnonymized = isAnonymized;
    }
}
