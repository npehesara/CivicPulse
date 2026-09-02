package civicpulse_backend.service;

import civicpulse_backend.dto.image.CreateImageRequest;
import civicpulse_backend.dto.image.ImageResponse;
import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.IssueImage;
import civicpulse_backend.entity.Role;
import civicpulse_backend.entity.User;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.IssueImageRepository;
import civicpulse_backend.repository.IssueRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class IssueImageService {

    private final IssueImageRepository imageRepository;
    private final IssueRepository issueRepository;
    private final SecurityUtils securityUtils;

    public IssueImageService(IssueImageRepository imageRepository,
                             IssueRepository issueRepository,
                             SecurityUtils securityUtils) {
        this.imageRepository = imageRepository;
        this.issueRepository = issueRepository;
        this.securityUtils = securityUtils;
    }

    @Transactional
    public ImageResponse addImageToIssue(Long issueId, CreateImageRequest request) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + issueId));

        User currentUser = securityUtils.getCurrentUser();
        boolean isOwner = issue.getUser().getUserId().equals(currentUser.getUserId());
        boolean isStaff = currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.OFFICIAL;

        if (!isOwner && !isStaff) {
            throw new UnauthorizedOperationException("Only the issue reporter or staff can attach images");
        }

        IssueImage image = new IssueImage();
        image.setImageUrl(request.getImageUrl().trim());
        image.setOriginalFilename(request.getOriginalFilename());
        image.setAiSafetyScore(request.getAiSafetyScore());
        image.setAiRelevanceScore(request.getAiRelevanceScore());
        image.setIsAnonymized(request.getIsAnonymized() != null ? request.getIsAnonymized() : false);
        image.setUploadedAt(LocalDateTime.now());
        image.setIssue(issue);

        IssueImage saved = imageRepository.save(image);
        return ImageResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ImageResponse> getImagesForIssue(Long issueId) {
        if (!issueRepository.existsById(issueId)) {
            throw new ResourceNotFoundException("Issue not found with id: " + issueId);
        }
        return imageRepository.findByIssue_IssueId(issueId).stream()
                .map(ImageResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteImage(Long issueId, Long imageId) {
        IssueImage image = imageRepository.findById(imageId)
                .orElseThrow(() -> new ResourceNotFoundException("Image not found with id: " + imageId));

        if (!image.getIssue().getIssueId().equals(issueId)) {
            throw new IllegalArgumentException("Image does not belong to issue with id: " + issueId);
        }

        User currentUser = securityUtils.getCurrentUser();
        boolean isOwner = image.getIssue().getUser().getUserId().equals(currentUser.getUserId());
        boolean isStaff = currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.OFFICIAL;

        if (!isOwner && !isStaff) {
            throw new UnauthorizedOperationException("You do not have permission to delete this image");
        }

        imageRepository.delete(image);
    }
}
