package civicpulse_backend.repository;

import civicpulse_backend.entity.Resolution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ResolutionRepository extends JpaRepository<Resolution, Long> {
    Optional<Resolution> findByIssue_IssueId(Long issueId);
    boolean existsByIssue_IssueId(Long issueId);
}
