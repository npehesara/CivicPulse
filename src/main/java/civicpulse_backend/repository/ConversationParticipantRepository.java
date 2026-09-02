package civicpulse_backend.repository;

import civicpulse_backend.entity.ConversationParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationParticipantRepository extends JpaRepository<ConversationParticipant, Long> {

    Optional<ConversationParticipant> findByConversation_ConversationIdAndUser_UserId(Long conversationId, Long userId);

    boolean existsByConversation_ConversationIdAndUser_UserId(Long conversationId, Long userId);

    List<ConversationParticipant> findByConversation_ConversationId(Long conversationId);
}
