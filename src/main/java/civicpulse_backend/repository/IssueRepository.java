package civicpulse_backend.repository;

import civicpulse_backend.entity.Issue;
import civicpulse_backend.entity.Visibility;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IssueRepository extends JpaRepository<Issue, Long>, JpaSpecificationExecutor<Issue> {
    List<Issue> findByUser_UserId(Long userId);
    List<Issue> findByDepartment_DepartmentId(Long departmentId);
    List<Issue> findByTerritory_TerritoryId(Long territoryId);
    long countByUser_UserId(Long userId);
    long countByUser_UserIdAndVisibility(Long userId, Visibility visibility);
}
