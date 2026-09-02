package civicpulse_backend.repository;

import civicpulse_backend.entity.Upvote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UpvoteRepository extends JpaRepository<Upvote, Long> {
    Optional<Upvote> findByIssue_IssueIdAndUser_UserId(Long issueId, Long userId);
    boolean existsByIssue_IssueIdAndUser_UserId(Long issueId, Long userId);
    long countByIssue_IssueId(Long issueId);
    long countByUser_UserId(Long userId);
    void deleteByIssue_IssueIdAndUser_UserId(Long issueId, Long userId);
}
