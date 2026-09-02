package civicpulse_backend.service;

import civicpulse_backend.dto.message.ConversationResponse;
import civicpulse_backend.dto.message.CreateConversationRequest;
import civicpulse_backend.dto.message.MessageResponse;
import civicpulse_backend.dto.message.SendMessageRequest;
import civicpulse_backend.entity.*;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.exception.UnauthorizedOperationException;
import civicpulse_backend.repository.ConversationParticipantRepository;
import civicpulse_backend.repository.ConversationRepository;
import civicpulse_backend.repository.MessageRepository;
import civicpulse_backend.repository.UserRepository;
import civicpulse_backend.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class MessageService {

    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final SecurityUtils securityUtils;

    public MessageService(ConversationRepository conversationRepository,
                          ConversationParticipantRepository participantRepository,
                          MessageRepository messageRepository,
                          UserRepository userRepository,
                          NotificationService notificationService,
                          SecurityUtils securityUtils) {
        this.conversationRepository = conversationRepository;
        this.participantRepository = participantRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.securityUtils = securityUtils;
    }

    @Transactional(readOnly = true)
    public List<ConversationResponse> getUserConversations() {
        User currentUser = securityUtils.getCurrentUser();
        List<Conversation> conversations = conversationRepository.findAllByUserId(currentUser.getUserId());

        return conversations.stream()
                .map(c -> {
                    long unreadCount = messageRepository.countUnreadMessagesForUser(c.getConversationId(), currentUser.getUserId());
                    return ConversationResponse.fromEntity(c, currentUser.getUserId(), unreadCount);
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public ConversationResponse createOrGetConversation(CreateConversationRequest request) {
        User currentUser = securityUtils.getCurrentUser();

        if (currentUser.getUserId().equals(request.getRecipientUserId())) {
            throw new IllegalArgumentException("Cannot start a conversation with yourself");
        }

        User recipient = userRepository.findById(request.getRecipientUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Recipient user not found with id: " + request.getRecipientUserId()));

        Optional<Conversation> existing = conversationRepository.findDirectConversationBetween(currentUser.getUserId(), recipient.getUserId());

        Conversation conversation;
        if (existing.isPresent()) {
            conversation = existing.get();
        } else {
            conversation = new Conversation();
            conversation.setCreatedAt(LocalDateTime.now());
            conversation.setUpdatedAt(LocalDateTime.now());
            conversation = conversationRepository.save(conversation);

            ConversationParticipant p1 = new ConversationParticipant(conversation, currentUser);
            ConversationParticipant p2 = new ConversationParticipant(conversation, recipient);
            participantRepository.save(p1);
            participantRepository.save(p2);

            conversation.getParticipants().add(p1);
            conversation.getParticipants().add(p2);
        }

        if (request.getInitialMessage() != null && !request.getInitialMessage().isBlank()) {
            sendMessageInternal(conversation, currentUser, recipient, request.getInitialMessage().trim());
        }

        long unread = messageRepository.countUnreadMessagesForUser(conversation.getConversationId(), currentUser.getUserId());
        return ConversationResponse.fromEntity(conversation, currentUser.getUserId(), unread);
    }

    @Transactional
    public List<MessageResponse> getConversationMessages(Long conversationId) {
        User currentUser = securityUtils.getCurrentUser();

        ConversationParticipant participant = participantRepository
                .findByConversation_ConversationIdAndUser_UserId(conversationId, currentUser.getUserId())
                .orElseThrow(() -> new UnauthorizedOperationException("You are not a participant in this conversation"));

        List<Message> messages = messageRepository.findByConversation_ConversationIdOrderBySentAtAsc(conversationId);

        // Mark unread messages as read
        for (Message m : messages) {
            if (!m.getSender().getUserId().equals(currentUser.getUserId()) && !Boolean.TRUE.equals(m.getIsRead())) {
                m.setIsRead(true);
                messageRepository.save(m);
            }
        }

        participant.setLastReadAt(LocalDateTime.now());
        participantRepository.save(participant);

        return messages.stream()
                .map(m -> MessageResponse.fromEntity(m, currentUser.getUserId()))
                .collect(Collectors.toList());
    }

    @Transactional
    public MessageResponse sendMessage(Long conversationId, SendMessageRequest request) {
        User currentUser = securityUtils.getCurrentUser();

        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found with id: " + conversationId));

        boolean isParticipant = participantRepository.existsByConversation_ConversationIdAndUser_UserId(conversationId, currentUser.getUserId());
        if (!isParticipant) {
            throw new UnauthorizedOperationException("You are not a participant in this conversation");
        }

        List<ConversationParticipant> participants = participantRepository.findByConversation_ConversationId(conversationId);
        User recipient = participants.stream()
                .map(ConversationParticipant::getUser)
                .filter(u -> !u.getUserId().equals(currentUser.getUserId()))
                .findFirst()
                .orElse(null);

        Message savedMessage = sendMessageInternal(conversation, currentUser, recipient, request.getContent().trim());

        return MessageResponse.fromEntity(savedMessage, currentUser.getUserId());
    }

    @Transactional
    public void markConversationAsRead(Long conversationId) {
        User currentUser = securityUtils.getCurrentUser();

        ConversationParticipant participant = participantRepository
                .findByConversation_ConversationIdAndUser_UserId(conversationId, currentUser.getUserId())
                .orElseThrow(() -> new UnauthorizedOperationException("You are not a participant in this conversation"));

        List<Message> messages = messageRepository.findByConversation_ConversationIdOrderBySentAtAsc(conversationId);
        for (Message m : messages) {
            if (!m.getSender().getUserId().equals(currentUser.getUserId()) && !Boolean.TRUE.equals(m.getIsRead())) {
                m.setIsRead(true);
                messageRepository.save(m);
            }
        }

        participant.setLastReadAt(LocalDateTime.now());
        participantRepository.save(participant);
    }

    private Message sendMessageInternal(Conversation conversation, User sender, User recipient, String content) {
        Message message = new Message(conversation, sender, content);
        Message saved = messageRepository.save(message);

        conversation.setLastMessageText(content.length() > 100 ? content.substring(0, 97) + "..." : content);
        conversation.setLastMessageAt(LocalDateTime.now());
        conversation.setUpdatedAt(LocalDateTime.now());
        conversationRepository.save(conversation);

        if (recipient != null) {
            notificationService.createNotification(
                    recipient,
                    null,
                    "New message from " + sender.getFullName(),
                    content.length() > 60 ? content.substring(0, 57) + "..." : content,
                    NotificationType.MESSAGE_RECEIVED
            );
        }

        return saved;
    }
}
