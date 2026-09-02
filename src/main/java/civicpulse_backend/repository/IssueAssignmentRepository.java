package civicpulse_backend.repository;

import civicpulse_backend.entity.IssueAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IssueAssignmentRepository extends JpaRepository<IssueAssignment, Long> {
    List<IssueAssignment> findByIssue_IssueIdOrderByAssignedAtDesc(Long issueId);
    List<IssueAssignment> findByDepartment_DepartmentId(Long departmentId);
    List<IssueAssignment> findByAssignedUser_UserId(Long userId);
}
