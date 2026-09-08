package civicpulse_backend.exception;

/**
 * Thrown when an image file fails validation (unsupported MIME, size limit exceeded)
 * or encounters a failure during cloud upload/processing.
 */
public class ImageUploadException extends RuntimeException {

    public ImageUploadException(String message) {
        super(message);
    }

    public ImageUploadException(String message, Throwable cause) {
        super(message, cause);
    }
}
