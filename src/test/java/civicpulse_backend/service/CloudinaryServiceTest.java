package civicpulse_backend.service;

import civicpulse_backend.dto.image.CloudinaryUploadResult;
import civicpulse_backend.exception.ImageUploadException;
import com.cloudinary.Cloudinary;
import com.cloudinary.Uploader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CloudinaryServiceTest {

    @Mock
    private Cloudinary cloudinary;

    @Mock
    private Uploader uploader;

    private CloudinaryService cloudinaryService;

    @BeforeEach
    void setUp() {
        cloudinaryService = new CloudinaryService(cloudinary);
    }

    @Test
    @DisplayName("Should throw ImageUploadException when file is null or empty")
    void shouldThrowExceptionWhenFileNullOrEmpty() {
        MockMultipartFile emptyFile = new MockMultipartFile("file", "empty.jpg", "image/jpeg", new byte[0]);

        ImageUploadException ex1 = assertThrows(ImageUploadException.class,
                () -> cloudinaryService.uploadImage(null, CloudinaryService.FOLDER_ISSUES));
        assertTrue(ex1.getMessage().contains("Cannot upload an empty or null file"));

        ImageUploadException ex2 = assertThrows(ImageUploadException.class,
                () -> cloudinaryService.uploadImage(emptyFile, CloudinaryService.FOLDER_ISSUES));
        assertTrue(ex2.getMessage().contains("Cannot upload an empty or null file"));
    }

    @Test
    @DisplayName("Should throw ImageUploadException for unsupported MIME types")
    void shouldThrowExceptionForUnsupportedMimeTypes() {
        MockMultipartFile pdfFile = new MockMultipartFile("file", "doc.pdf", "application/pdf", "dummy pdf content".getBytes());
        MockMultipartFile exeFile = new MockMultipartFile("file", "app.exe", "application/x-msdownload", "dummy binary".getBytes());
        MockMultipartFile textFile = new MockMultipartFile("file", "text.txt", "text/plain", "hello world".getBytes());

        assertThrows(ImageUploadException.class, () -> cloudinaryService.uploadImage(pdfFile, CloudinaryService.FOLDER_ISSUES));
        assertThrows(ImageUploadException.class, () -> cloudinaryService.uploadImage(exeFile, CloudinaryService.FOLDER_ISSUES));
        assertThrows(ImageUploadException.class, () -> cloudinaryService.uploadImage(textFile, CloudinaryService.FOLDER_ISSUES));
    }

    @Test
    @DisplayName("Should accept all allowed MIME types (jpeg, jpg, pjpeg, png, webp, heic, gif)")
    void shouldAcceptAllAllowedMimeTypes() throws IOException {
        when(cloudinary.uploader()).thenReturn(uploader);

        String[] allowedMimes = {"image/jpeg", "image/jpg", "image/pjpeg", "image/png", "image/webp", "image/heic", "image/gif"};
        Map<String, Object> mockResponse = Map.of(
                "secure_url", "https://res.cloudinary.com/demo/image/upload/sample.jpg",
                "public_id", "civicpulse/issues/sample"
        );
        when(uploader.upload(any(byte[].class), any(Map.class))).thenReturn(mockResponse);

        for (String mime : allowedMimes) {
            MockMultipartFile file = new MockMultipartFile("file", "test_image", mime, "valid image bytes".getBytes());
            CloudinaryUploadResult result = cloudinaryService.uploadImage(file, CloudinaryService.FOLDER_ISSUES);
            assertNotNull(result);
            assertEquals("https://res.cloudinary.com/demo/image/upload/sample.jpg", result.secureUrl());
        }
    }

    @Test
    @DisplayName("Should accept octet-stream with valid image file extension fallback")
    void shouldAcceptOctetStreamWithValidExtensionFallback() throws IOException {
        when(cloudinary.uploader()).thenReturn(uploader);

        Map<String, Object> mockResponse = Map.of(
                "secure_url", "https://res.cloudinary.com/demo/image/upload/sample.jpg",
                "public_id", "civicpulse/profiles/sample"
        );
        when(uploader.upload(any(byte[].class), any(Map.class))).thenReturn(mockResponse);

        MockMultipartFile jpgFile = new MockMultipartFile("file", "my_photo.jpg", "application/octet-stream", "valid jpg bytes".getBytes());
        CloudinaryUploadResult resultJpg = cloudinaryService.uploadProfileImage(jpgFile);
        assertNotNull(resultJpg);

        MockMultipartFile pngFile = new MockMultipartFile("file", "avatar.png", "application/octet-stream", "valid png bytes".getBytes());
        CloudinaryUploadResult resultPng = cloudinaryService.uploadProfileImage(pngFile);
        assertNotNull(resultPng);
    }

    @Test
    @DisplayName("Should throw ImageUploadException when profile image exceeds 5 MB")
    void shouldThrowExceptionWhenProfileImageExceeds5MB() {
        byte[] largeBytes = new byte[5 * 1024 * 1024 + 1]; // 5 MB + 1 byte
        MockMultipartFile largeFile = new MockMultipartFile("file", "large_avatar.jpg", "image/jpeg", largeBytes);

        ImageUploadException ex = assertThrows(ImageUploadException.class,
                () -> cloudinaryService.uploadProfileImage(largeFile));
        assertTrue(ex.getMessage().contains("exceeds maximum allowed limit"));
    }

    @Test
    @DisplayName("Should throw ImageUploadException when issue image exceeds 10 MB")
    void shouldThrowExceptionWhenIssueImageExceeds10MB() {
        byte[] largeBytes = new byte[10 * 1024 * 1024 + 1]; // 10 MB + 1 byte
        MockMultipartFile largeFile = new MockMultipartFile("file", "large_issue.jpg", "image/jpeg", largeBytes);

        ImageUploadException ex = assertThrows(ImageUploadException.class,
                () -> cloudinaryService.uploadIssueImage(largeFile));
        assertTrue(ex.getMessage().contains("exceeds maximum allowed limit"));
    }

    @Test
    @DisplayName("Should successfully upload image and return full CloudinaryUploadResult")
    void shouldUploadImageSuccessfully() throws IOException {
        when(cloudinary.uploader()).thenReturn(uploader);

        byte[] content = "valid image data".getBytes();
        MockMultipartFile file = new MockMultipartFile("file", "photo.jpg", "image/jpeg", content);

        Map<String, Object> mockResponse = Map.of(
                "secure_url", "https://res.cloudinary.com/demo/image/upload/v12345/civicpulse/issues/sample.jpg",
                "public_id", "civicpulse/issues/sample",
                "format", "jpg",
                "bytes", 15420L,
                "width", 1024,
                "height", 768
        );

        when(uploader.upload(eq(content), any(Map.class))).thenReturn(mockResponse);

        CloudinaryUploadResult result = cloudinaryService.uploadIssueImage(file);

        assertNotNull(result);
        assertEquals("https://res.cloudinary.com/demo/image/upload/v12345/civicpulse/issues/sample.jpg", result.secureUrl());
        assertEquals("civicpulse/issues/sample", result.publicId());
        assertEquals("jpg", result.format());
        assertEquals(15420L, result.bytes());
        assertEquals(1024, result.width());
        assertEquals(768, result.height());
    }

    @Test
    @DisplayName("Should wrap IOException in ImageUploadException on Cloudinary communication failure")
    void shouldWrapIOExceptionInImageUploadException() throws IOException {
        when(cloudinary.uploader()).thenReturn(uploader);
        when(uploader.upload(any(byte[].class), any(Map.class))).thenThrow(new IOException("Network timeout"));

        MockMultipartFile file = new MockMultipartFile("file", "photo.jpg", "image/jpeg", "image bytes".getBytes());

        ImageUploadException ex = assertThrows(ImageUploadException.class,
                () -> cloudinaryService.uploadIssueImage(file));
        assertTrue(ex.getMessage().contains("Failed to upload image to cloud storage"));
        assertNotNull(ex.getCause());
    }

    @Test
    @DisplayName("Should safely reject delete requests with blank or non-civicpulse public IDs")
    void shouldRejectInvalidDeletePublicIds() {
        assertFalse(cloudinaryService.deleteImage(null));
        assertFalse(cloudinaryService.deleteImage(""));
        assertFalse(cloudinaryService.deleteImage("   "));
        assertFalse(cloudinaryService.deleteImage("malicious_folder/other_user_file"));
        assertFalse(cloudinaryService.deleteImage("root_file"));

        verifyNoInteractions(cloudinary);
    }

    @Test
    @DisplayName("Should successfully delete image when valid civicpulse public ID is provided")
    void shouldDeleteImageSuccessfully() throws IOException {
        when(cloudinary.uploader()).thenReturn(uploader);

        Map<String, Object> mockResponse = Map.of("result", "ok");
        when(uploader.destroy(eq("civicpulse/issues/sample_123"), any(Map.class))).thenReturn(mockResponse);

        boolean deleted = cloudinaryService.deleteImage("civicpulse/issues/sample_123");

        assertTrue(deleted);
        verify(uploader, times(1)).destroy(eq("civicpulse/issues/sample_123"), any(Map.class));
    }
}
