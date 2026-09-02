package civicpulse_backend.service;

import civicpulse_backend.dto.status.StatusRequest;
import civicpulse_backend.dto.status.StatusResponse;
import civicpulse_backend.entity.IssueStatus;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueStatusRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class IssueStatusService {

    private final IssueStatusRepository statusRepository;

    public IssueStatusService(IssueStatusRepository statusRepository) {
        this.statusRepository = statusRepository;
    }

    @Transactional
    public StatusResponse createStatus(StatusRequest request) {
        String name = request.getStatusName().trim().toUpperCase();
        if (statusRepository.existsByStatusName(name)) {
            throw new ConflictException("Status already exists with name: " + name);
        }

        IssueStatus status = new IssueStatus();
        status.setStatusName(name);
        status.setDescription(request.getDescription());

        IssueStatus saved = statusRepository.save(status);
        return StatusResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<StatusResponse> getAllStatuses() {
        return statusRepository.findAll().stream()
                .map(StatusResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public StatusResponse getStatusById(Long id) {
        IssueStatus status = statusRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Status not found with id: " + id));
        return StatusResponse.fromEntity(status);
    }

    @Transactional
    public StatusResponse updateStatus(Long id, StatusRequest request) {
        IssueStatus status = statusRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Status not found with id: " + id));

        String name = request.getStatusName().trim().toUpperCase();
        if (!status.getStatusName().equalsIgnoreCase(name) && statusRepository.existsByStatusName(name)) {
            throw new ConflictException("Status already exists with name: " + name);
        }

        status.setStatusName(name);
        status.setDescription(request.getDescription());

        IssueStatus saved = statusRepository.save(status);
        return StatusResponse.fromEntity(saved);
    }

    @Transactional
    public void deleteStatus(Long id) {
        if (!statusRepository.existsById(id)) {
            throw new ResourceNotFoundException("Status not found with id: " + id);
        }
        statusRepository.deleteById(id);
    }

    @Transactional
    public IssueStatus getOrCreateStatus(String statusName, String defaultDescription) {
        return statusRepository.findByStatusName(statusName.toUpperCase())
                .orElseGet(() -> statusRepository.save(new IssueStatus(statusName.toUpperCase(), defaultDescription)));
    }
}
