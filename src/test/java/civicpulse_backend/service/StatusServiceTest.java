package civicpulse_backend.service;

import civicpulse_backend.dto.status.StatusRequest;
import civicpulse_backend.dto.status.StatusResponse;
import civicpulse_backend.entity.IssueStatus;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueStatusRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StatusServiceTest {

    @Mock
    private IssueStatusRepository statusRepository;

    @InjectMocks
    private IssueStatusService statusService;

    private IssueStatus status;

    @BeforeEach
    void setUp() {
        status = new IssueStatus("IN_PROGRESS", "Work currently in progress");
        status.setStatusId(1L);
    }

    @Test
    void shouldCreateStatusSuccessfully() {
        StatusRequest request = new StatusRequest("IN_PROGRESS", "Work currently in progress");
        when(statusRepository.existsByStatusName("IN_PROGRESS")).thenReturn(false);
        when(statusRepository.save(any(IssueStatus.class))).thenReturn(status);

        StatusResponse response = statusService.createStatus(request);

        assertNotNull(response);
        assertEquals("IN_PROGRESS", response.getStatusName());
    }

    @Test
    void shouldThrowExceptionWhenDuplicateStatusName() {
        StatusRequest request = new StatusRequest("IN_PROGRESS", "Work currently in progress");
        when(statusRepository.existsByStatusName("IN_PROGRESS")).thenReturn(true);

        assertThrows(ConflictException.class, () -> statusService.createStatus(request));
    }

    @Test
    void shouldGetStatusById() {
        when(statusRepository.findById(1L)).thenReturn(Optional.of(status));

        StatusResponse response = statusService.getStatusById(1L);
        assertNotNull(response);
        assertEquals("IN_PROGRESS", response.getStatusName());
    }

    @Test
    void shouldGetAllStatuses() {
        when(statusRepository.findAll()).thenReturn(List.of(status));

        List<StatusResponse> list = statusService.getAllStatuses();
        assertEquals(1, list.size());
    }

    @Test
    void shouldDeleteStatusSuccessfully() {
        when(statusRepository.existsById(1L)).thenReturn(true);

        statusService.deleteStatus(1L);
        verify(statusRepository).deleteById(1L);
    }
}
