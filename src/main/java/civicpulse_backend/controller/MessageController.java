package civicpulse_backend.controller;

import civicpulse_backend.dto.message.ConversationResponse;
import civicpulse_backend.dto.message.CreateConversationRequest;
import civicpulse_backend.dto.message.MessageResponse;
import civicpulse_backend.dto.message.SendMessageRequest;
import civicpulse_backend.service.MessageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/conversations")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }

    @GetMapping
    public ResponseEntity<List<ConversationResponse>> getUserConversations() {
        List<ConversationResponse> response = messageService.getUserConversations();
        return ResponseEntity.ok(response);
    }

    @PostMapping
    public ResponseEntity<ConversationResponse> createOrGetConversation(@Valid @RequestBody CreateConversationRequest request) {
        ConversationResponse response = messageService.createOrGetConversation(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{conversationId}/messages")
    public ResponseEntity<List<MessageResponse>> getConversationMessages(@PathVariable Long conversationId) {
        List<MessageResponse> response = messageService.getConversationMessages(conversationId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{conversationId}/messages")
    public ResponseEntity<MessageResponse> sendMessage(@PathVariable Long conversationId, @Valid @RequestBody SendMessageRequest request) {
        MessageResponse response = messageService.sendMessage(conversationId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{conversationId}/read")
    public ResponseEntity<Void> markConversationAsRead(@PathVariable Long conversationId) {
        messageService.markConversationAsRead(conversationId);
        return ResponseEntity.noContent().build();
    }
}
