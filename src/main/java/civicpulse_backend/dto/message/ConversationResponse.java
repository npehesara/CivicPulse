package civicpulse_backend.dto.message;

import civicpulse_backend.dto.user.PublicUserResponse;
import civicpulse_backend.entity.Conversation;
import civicpulse_backend.entity.ConversationParticipant;
import civicpulse_backend.entity.User;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ConversationResponse {

    private Long conversationId;
    private String title;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String lastMessageText;
    private LocalDateTime lastMessageAt;
    private long unreadCount;
    private PublicUserResponse otherParticipant;
    private List<PublicUserResponse> participants = new ArrayList<>();

    public ConversationResponse() {
    }

    public static ConversationResponse fromEntity(Conversation conversation, Long currentUserId, long unreadCount) {
        if (conversation == null) return null;
        ConversationResponse response = new ConversationResponse();
        response.setConversationId(conversation.getConversationId());
        response.setTitle(conversation.getTitle());
        response.setCreatedAt(conversation.getCreatedAt());
        response.setUpdatedAt(conversation.getUpdatedAt());
        response.setLastMessageText(conversation.getLastMessageText());
        response.setLastMessageAt(conversation.getLastMessageAt());
        response.setUnreadCount(unreadCount);

        if (conversation.getParticipants() != null) {
            for (ConversationParticipant cp : conversation.getParticipants()) {
                User u = cp.getUser();
                if (u != null) {
                    PublicUserResponse pur = PublicUserResponse.fromEntity(u);
                    response.getParticipants().add(pur);
                    if (currentUserId != null && !currentUserId.equals(u.getUserId())) {
                        response.setOtherParticipant(pur);
                    }
                }
            }
        }

        // If no custom title and 1-on-1, use other participant's name
        if ((response.getTitle() == null || response.getTitle().isBlank()) && response.getOtherParticipant() != null) {
            response.setTitle(response.getOtherParticipant().getFullName());
        }

        return response;
    }

    public Long getConversationId() {
        return conversationId;
    }

    public void setConversationId(Long conversationId) {
        this.conversationId = conversationId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public String getLastMessageText() {
        return lastMessageText;
    }

    public void setLastMessageText(String lastMessageText) {
        this.lastMessageText = lastMessageText;
    }

    public LocalDateTime getLastMessageAt() {
        return lastMessageAt;
    }

    public void setLastMessageAt(LocalDateTime lastMessageAt) {
        this.lastMessageAt = lastMessageAt;
    }

    public long getUnreadCount() {
        return unreadCount;
    }

    public void setUnreadCount(long unreadCount) {
        this.unreadCount = unreadCount;
    }

    public PublicUserResponse getOtherParticipant() {
        return otherParticipant;
    }

    public void setOtherParticipant(PublicUserResponse otherParticipant) {
        this.otherParticipant = otherParticipant;
    }

    public List<PublicUserResponse> getParticipants() {
        return participants;
    }

    public void setParticipants(List<PublicUserResponse> participants) {
        this.participants = participants;
    }
}
