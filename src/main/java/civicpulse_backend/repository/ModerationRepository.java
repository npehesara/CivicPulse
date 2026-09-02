package civicpulse_backend.repository;

import civicpulse_backend.entity.Moderation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ModerationRepository extends JpaRepository<Moderation, Long> {
    Optional<Moderation> findByIssue_IssueId(Long issueId);
}
