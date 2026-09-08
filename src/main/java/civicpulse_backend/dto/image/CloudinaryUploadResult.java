package civicpulse_backend.dto.image;

/**
 * Result data transfer object returned after uploading a media asset to Cloudinary.
 */
public record CloudinaryUploadResult(
        String secureUrl,
        String publicId,
        String format,
        Long bytes,
        Integer width,
        Integer height
) {}
