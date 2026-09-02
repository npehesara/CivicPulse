package civicpulse_backend.repository;

import civicpulse_backend.entity.IssueImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IssueImageRepository extends JpaRepository<IssueImage, Long> {
    List<IssueImage> findByIssue_IssueId(Long issueId);
}
