package civicpulse_backend.repository;

import civicpulse_backend.entity.IssueCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IssueCategoryRepository extends JpaRepository<IssueCategory, Long> {
    boolean existsByCategoryName(String categoryName);
    Optional<IssueCategory> findByCategoryName(String categoryName);
}
