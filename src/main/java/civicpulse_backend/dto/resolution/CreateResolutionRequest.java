package civicpulse_backend.dto.resolution;

import jakarta.validation.constraints.NotBlank;

public class CreateResolutionRequest {

    @NotBlank(message = "Resolution description is required")
    private String resolutionDescription;

    private String resolutionImage;

    public CreateResolutionRequest() {
    }

    public CreateResolutionRequest(String resolutionDescription, String resolutionImage) {
        this.resolutionDescription = resolutionDescription;
        this.resolutionImage = resolutionImage;
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
}
