package civicpulse_backend.repository;

import civicpulse_backend.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByIssue_IssueIdAndIsDeletedFalseOrderByCreatedAtAsc(Long issueId);
}
