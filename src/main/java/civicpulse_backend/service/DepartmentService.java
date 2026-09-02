package civicpulse_backend.service;

import civicpulse_backend.dto.department.DepartmentRequest;
import civicpulse_backend.dto.department.DepartmentResponse;
import civicpulse_backend.entity.Department;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.DepartmentRepository;
import civicpulse_backend.repository.TerritoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class DepartmentService {

    private final DepartmentRepository departmentRepository;
    private final TerritoryRepository territoryRepository;

    public DepartmentService(DepartmentRepository departmentRepository, TerritoryRepository territoryRepository) {
        this.departmentRepository = departmentRepository;
        this.territoryRepository = territoryRepository;
    }

    @Transactional
    public DepartmentResponse createDepartment(DepartmentRequest request) {
        Department department = new Department();
        department.setDepartmentName(request.getDepartmentName().trim());
        department.setDescription(request.getDescription());
        department.setContactNumber(request.getContactNumber());
        department.setEmail(request.getEmail());

        if (request.getTerritoryId() != null) {
            Territory territory = territoryRepository.findById(request.getTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + request.getTerritoryId()));
            department.setTerritory(territory);
        }

        Department saved = departmentRepository.save(department);
        return DepartmentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<DepartmentResponse> getAllDepartments(Long territoryId) {
        List<Department> departments;
        if (territoryId != null) {
            departments = departmentRepository.findByTerritory_TerritoryId(territoryId);
        } else {
            departments = departmentRepository.findAll();
        }
        return departments.stream()
                .map(DepartmentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DepartmentResponse getDepartmentById(Long id) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + id));
        return DepartmentResponse.fromEntity(department);
    }

    @Transactional
    public DepartmentResponse updateDepartment(Long id, DepartmentRequest request) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + id));

        department.setDepartmentName(request.getDepartmentName().trim());
        department.setDescription(request.getDescription());
        department.setContactNumber(request.getContactNumber());
        department.setEmail(request.getEmail());

        if (request.getTerritoryId() != null) {
            Territory territory = territoryRepository.findById(request.getTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Territory not found with id: " + request.getTerritoryId()));
            department.setTerritory(territory);
        } else {
            department.setTerritory(null);
        }

        Department saved = departmentRepository.save(department);
        return DepartmentResponse.fromEntity(saved);
    }

    @Transactional
    public void deleteDepartment(Long id) {
        if (!departmentRepository.existsById(id)) {
            throw new ResourceNotFoundException("Department not found with id: " + id);
        }
        departmentRepository.deleteById(id);
    }
}
