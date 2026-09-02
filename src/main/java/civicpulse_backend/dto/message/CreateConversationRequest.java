package civicpulse_backend.dto.message;

import jakarta.validation.constraints.NotNull;

public class CreateConversationRequest {

    @NotNull(message = "Recipient user ID is required")
    private Long recipientUserId;

    private String initialMessage;

    public CreateConversationRequest() {
    }

    public CreateConversationRequest(Long recipientUserId, String initialMessage) {
        this.recipientUserId = recipientUserId;
        this.initialMessage = initialMessage;
    }

    public Long getRecipientUserId() {
        return recipientUserId;
    }

    public void setRecipientUserId(Long recipientUserId) {
        this.recipientUserId = recipientUserId;
    }

    public String getInitialMessage() {
        return initialMessage;
    }

    public void setInitialMessage(String initialMessage) {
        this.initialMessage = initialMessage;
    }
}
