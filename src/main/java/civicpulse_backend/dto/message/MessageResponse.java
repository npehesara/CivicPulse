package civicpulse_backend.dto.message;

import civicpulse_backend.entity.Message;

import java.time.LocalDateTime;

public class MessageResponse {

    private Long messageId;
    private Long conversationId;
    private Long senderId;
    private String senderName;
    private String senderProfileImage;
    private String content;
    private LocalDateTime sentAt;
    private Boolean isRead;
    private Boolean isMine;

    public MessageResponse() {
    }

    public static MessageResponse fromEntity(Message message, Long currentUserId) {
        if (message == null) return null;
        MessageResponse response = new MessageResponse();
        response.setMessageId(message.getMessageId());
        if (message.getConversation() != null) {
            response.setConversationId(message.getConversation().getConversationId());
        }
        if (message.getSender() != null) {
            response.setSenderId(message.getSender().getUserId());
            response.setSenderName(message.getSender().getFullName());
            response.setSenderProfileImage(message.getSender().getProfileImage());
            response.setIsMine(currentUserId != null && currentUserId.equals(message.getSender().getUserId()));
        }
        response.setContent(message.getContent());
        response.setSentAt(message.getSentAt());
        response.setIsRead(message.getIsRead());
        return response;
    }

    public Long getMessageId() {
        return messageId;
    }

    public void setMessageId(Long messageId) {
        this.messageId = messageId;
    }

    public Long getConversationId() {
        return conversationId;
    }

    public void setConversationId(Long conversationId) {
        this.conversationId = conversationId;
    }

    public Long getSenderId() {
        return senderId;
    }

    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }

    public String getSenderName() {
        return senderName;
    }

    public void setSenderName(String senderName) {
        this.senderName = senderName;
    }

    public String getSenderProfileImage() {
        return profileImage();
    }

    public String profileImage() {
        return senderProfileImage;
    }

    public String getSenderProfileImageValue() {
        return senderProfileImage;
    }

    public void setSenderProfileImage(String senderProfileImage) {
        this.senderProfileImage = senderProfileImage;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public LocalDateTime getSentAt() {
        return sentAt;
    }

    public void setSentAt(LocalDateTime sentAt) {
        this.sentAt = sentAt;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }

    public Boolean getIsMine() {
        return isMine;
    }

    public void setIsMine(Boolean isMine) {
        this.isMine = isMine;
    }
}
