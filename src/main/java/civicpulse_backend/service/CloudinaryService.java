package civicpulse_backend.service;

import civicpulse_backend.dto.image.CloudinaryUploadResult;
import civicpulse_backend.exception.ImageUploadException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.Set;

/**
 * Reusable service for uploading, managing, and safely deleting media assets on Cloudinary.
 * Used across both User Profile pictures and Issue Images with strict MIME and size validations.
 */
@Service
public class CloudinaryService {

    private static final Logger log = LoggerFactory.getLogger(CloudinaryService.class);

    public static final long MAX_PROFILE_IMAGE_SIZE = 5 * 1024 * 1024L;  // 5 MB
    public static final long MAX_ISSUE_IMAGE_SIZE = 10 * 1024 * 1024L;    // 10 MB

    public static final String FOLDER_PROFILES = "civicpulse/profiles";
    public static final String FOLDER_ISSUES = "civicpulse/issues";
    public static final String REQUIRED_PUBLIC_ID_PREFIX = "civicpulse/";

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            "image/jpeg",
            "image/png",
            "image/webp",
            "image/heic",
            "image/gif"
    );

    private final Cloudinary cloudinary;

    public CloudinaryService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    /**
     * Uploads a user profile image (max 5 MB) to Cloudinary folder "civicpulse/profiles".
     */
    public CloudinaryUploadResult uploadProfileImage(MultipartFile file) {
        return uploadImage(file, FOLDER_PROFILES, MAX_PROFILE_IMAGE_SIZE);
    }

    /**
     * Uploads a civic issue image (max 10 MB) to Cloudinary folder "civicpulse/issues".
     */
    public CloudinaryUploadResult uploadIssueImage(MultipartFile file) {
        return uploadImage(file, FOLDER_ISSUES, MAX_ISSUE_IMAGE_SIZE);
    }

    /**
     * Uploads an image file to Cloudinary with explicit folder and size constraints.
     *
     * @param file the MultipartFile to upload
     * @param folder the target folder in Cloudinary (e.g., "civicpulse/profiles", "civicpulse/issues")
     * @param maxSizeBytes the maximum allowed file size in bytes
     * @return CloudinaryUploadResult containing secureUrl, publicId, format, dimensions, etc.
     * @throws ImageUploadException if validation fails or Cloudinary upload encounters an error
     */
    public CloudinaryUploadResult uploadImage(MultipartFile file, String folder, long maxSizeBytes) {
        validateImageFile(file, maxSizeBytes);

        String targetFolder = (folder != null && !folder.isBlank()) ? folder.trim() : FOLDER_ISSUES;

        try {
            Map<String, Object> params = ObjectUtils.asMap(
                    "folder", targetFolder,
                    "resource_type", "image",
                    "overwrite", false
            );

            @SuppressWarnings("unchecked")
            Map<String, Object> uploadResult = cloudinary.uploader().upload(file.getBytes(), params);

            String secureUrl = (String) uploadResult.get("secure_url");
            String publicId = (String) uploadResult.get("public_id");
            String format = (String) uploadResult.get("format");
            Long bytes = uploadResult.get("bytes") instanceof Number num ? num.longValue() : file.getSize();
            Integer width = uploadResult.get("width") instanceof Number num ? num.intValue() : null;
            Integer height = uploadResult.get("height") instanceof Number num ? num.intValue() : null;

            log.info("Successfully uploaded image to Cloudinary [folder: {}, publicId: {}]", targetFolder, publicId);
            return new CloudinaryUploadResult(secureUrl, publicId, format, bytes, width, height);

        } catch (IOException e) {
            log.error("Failed to read image bytes or communicate with Cloudinary: {}", e.getMessage(), e);
            throw new ImageUploadException("Failed to upload image to cloud storage: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Cloudinary upload rejected: {}", e.getMessage(), e);
            throw new ImageUploadException("Image upload processing failed: " + e.getMessage(), e);
        }
    }

    /**
     * Backward-compatible convenience method defaulting to 10 MB max size.
     */
    public CloudinaryUploadResult uploadImage(MultipartFile file, String folder) {
        return uploadImage(file, folder, MAX_ISSUE_IMAGE_SIZE);
    }

    /**
     * Safely deletes an image from Cloudinary using its public ID.
     * Enforces that the public ID must begin with "civicpulse/".
     *
     * @param publicId the Cloudinary public ID of the resource
     * @return true if deletion succeeded, false otherwise
     */
    public boolean deleteImage(String publicId) {
        if (publicId == null || publicId.isBlank()) {
            log.warn("Attempted to delete image with null or blank public ID");
            return false;
        }

        String trimmedPublicId = publicId.trim();
        if (!trimmedPublicId.startsWith(REQUIRED_PUBLIC_ID_PREFIX)) {
            log.warn("Rejected delete request for publicId outside civicpulse namespace: {}", trimmedPublicId);
            return false;
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> result = cloudinary.uploader().destroy(trimmedPublicId, ObjectUtils.emptyMap());
            String resultStatus = (String) result.get("result");
            boolean ok = "ok".equalsIgnoreCase(resultStatus);
            if (ok) {
                log.info("Successfully deleted image from Cloudinary: {}", trimmedPublicId);
            } else {
                log.warn("Cloudinary returned non-ok status for publicId {}: {}", trimmedPublicId, resultStatus);
            }
            return ok;
        } catch (Exception e) {
            log.error("Failed to delete image from Cloudinary [publicId: {}]: {}", trimmedPublicId, e.getMessage(), e);
            return false;
        }
    }

    private void validateImageFile(MultipartFile file, long maxSizeBytes) {
        if (file == null || file.isEmpty()) {
            throw new ImageUploadException("Cannot upload an empty or null file");
        }

        if (file.getSize() > maxSizeBytes) {
            throw new ImageUploadException(String.format(
                    "File size (%d bytes) exceeds maximum allowed limit of %d bytes (%.1f MB)",
                    file.getSize(), maxSizeBytes, (double) maxSizeBytes / (1024 * 1024)
            ));
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType.toLowerCase().trim())) {
            throw new ImageUploadException(String.format(
                    "Unsupported image content type: '%s'. Allowed types are: %s",
                    contentType, String.join(", ", ALLOWED_CONTENT_TYPES)
            ));
        }
    }
}
