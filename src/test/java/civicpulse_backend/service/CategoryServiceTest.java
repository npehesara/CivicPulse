package civicpulse_backend.service;

import civicpulse_backend.dto.category.CategoryRequest;
import civicpulse_backend.dto.category.CategoryResponse;
import civicpulse_backend.entity.IssueCategory;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueCategoryRepository;
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
class CategoryServiceTest {

    @Mock
    private IssueCategoryRepository categoryRepository;

    @InjectMocks
    private IssueCategoryService categoryService;

    private IssueCategory category;

    @BeforeEach
    void setUp() {
        category = new IssueCategory("Roads & Potholes", "Damaged roads and potholes");
        category.setCategoryId(1L);
    }

    @Test
    void shouldCreateCategorySuccessfully() {
        CategoryRequest request = new CategoryRequest("Roads & Potholes", "Damaged roads and potholes");
        when(categoryRepository.existsByCategoryName("Roads & Potholes")).thenReturn(false);
        when(categoryRepository.save(any(IssueCategory.class))).thenReturn(category);

        CategoryResponse response = categoryService.createCategory(request);

        assertNotNull(response);
        assertEquals("Roads & Potholes", response.getCategoryName());
        verify(categoryRepository).save(any(IssueCategory.class));
    }

    @Test
    void shouldThrowExceptionWhenCreatingDuplicateCategory() {
        CategoryRequest request = new CategoryRequest("Roads & Potholes", "Damaged roads and potholes");
        when(categoryRepository.existsByCategoryName("Roads & Potholes")).thenReturn(true);

        assertThrows(ConflictException.class, () -> categoryService.createCategory(request));
        verify(categoryRepository, never()).save(any(IssueCategory.class));
    }

    @Test
    void shouldGetCategoryById() {
        when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));

        CategoryResponse response = categoryService.getCategoryById(1L);
        assertNotNull(response);
        assertEquals(1L, response.getCategoryId());
    }

    @Test
    void shouldThrowExceptionWhenCategoryNotFound() {
        when(categoryRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> categoryService.getCategoryById(99L));
    }

    @Test
    void shouldGetAllCategories() {
        when(categoryRepository.findAll()).thenReturn(List.of(category));

        List<CategoryResponse> list = categoryService.getAllCategories();
        assertEquals(1, list.size());
    }

    @Test
    void shouldDeleteCategorySuccessfully() {
        when(categoryRepository.existsById(1L)).thenReturn(true);

        categoryService.deleteCategory(1L);
        verify(categoryRepository).deleteById(1L);
    }
}
