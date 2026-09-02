package civicpulse_backend.service;

import civicpulse_backend.dto.department.DepartmentRequest;
import civicpulse_backend.dto.department.DepartmentResponse;
import civicpulse_backend.entity.Department;
import civicpulse_backend.entity.Territory;
import civicpulse_backend.repository.DepartmentRepository;
import civicpulse_backend.repository.TerritoryRepository;
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
class DepartmentServiceTest {

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private TerritoryRepository territoryRepository;

    @InjectMocks
    private DepartmentService departmentService;

    private Department department;
    private Territory territory;

    @BeforeEach
    void setUp() {
        territory = new Territory("Colombo", "CITY", null, null);
        territory.setTerritoryId(1L);

        department = new Department("Public Works", "Road maintenance", "0112345678", "works@colombo.gov", territory);
        department.setDepartmentId(1L);
    }

    @Test
    void shouldCreateDepartmentSuccessfully() {
        DepartmentRequest request = new DepartmentRequest("Public Works", "Road maintenance", "0112345678", "works@colombo.gov", 1L);
        when(territoryRepository.findById(1L)).thenReturn(Optional.of(territory));
        when(departmentRepository.save(any(Department.class))).thenReturn(department);

        DepartmentResponse response = departmentService.createDepartment(request);
        assertNotNull(response);
        assertEquals("Public Works", response.getDepartmentName());
    }

    @Test
    void shouldGetDepartmentById() {
        when(departmentRepository.findById(1L)).thenReturn(Optional.of(department));

        DepartmentResponse response = departmentService.getDepartmentById(1L);
        assertNotNull(response);
        assertEquals(1L, response.getDepartmentId());
    }

    @Test
    void shouldGetAllDepartments() {
        when(departmentRepository.findAll()).thenReturn(List.of(department));

        List<DepartmentResponse> list = departmentService.getAllDepartments(null);
        assertEquals(1, list.size());
    }

    @Test
    void shouldDeleteDepartment() {
        when(departmentRepository.existsById(1L)).thenReturn(true);

        departmentService.deleteDepartment(1L);
        verify(departmentRepository).deleteById(1L);
    }
}
