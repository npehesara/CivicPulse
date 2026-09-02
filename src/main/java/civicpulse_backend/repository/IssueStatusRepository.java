package civicpulse_backend.repository;

import civicpulse_backend.entity.IssueStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IssueStatusRepository extends JpaRepository<IssueStatus, Long> {
    boolean existsByStatusName(String statusName);
    Optional<IssueStatus> findByStatusName(String statusName);
}
