package civicpulse_backend.dto.resolution;

public class UpdateResolutionRequest {

    private String resolutionDescription;
    private String resolutionImage;

    public UpdateResolutionRequest() {
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
