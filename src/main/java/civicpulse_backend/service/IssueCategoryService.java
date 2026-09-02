package civicpulse_backend.service;

import civicpulse_backend.dto.category.CategoryRequest;
import civicpulse_backend.dto.category.CategoryResponse;
import civicpulse_backend.entity.IssueCategory;
import civicpulse_backend.exception.ConflictException;
import civicpulse_backend.exception.ResourceNotFoundException;
import civicpulse_backend.repository.IssueCategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class IssueCategoryService {

    private final IssueCategoryRepository categoryRepository;

    public IssueCategoryService(IssueCategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Transactional
    public CategoryResponse createCategory(CategoryRequest request) {
        String name = request.getCategoryName().trim();
        if (categoryRepository.existsByCategoryName(name)) {
            throw new ConflictException("Category already exists with name: " + name);
        }

        IssueCategory category = new IssueCategory();
        category.setCategoryName(name);
        category.setDescription(request.getDescription());

        IssueCategory saved = categoryRepository.save(category);
        return CategoryResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> getAllCategories() {
        return categoryRepository.findAll().stream()
                .map(CategoryResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public CategoryResponse getCategoryById(Long id) {
        IssueCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
        return CategoryResponse.fromEntity(category);
    }

    @Transactional
    public CategoryResponse updateCategory(Long id, CategoryRequest request) {
        IssueCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));

        String name = request.getCategoryName().trim();
        if (!category.getCategoryName().equalsIgnoreCase(name) && categoryRepository.existsByCategoryName(name)) {
            throw new ConflictException("Category already exists with name: " + name);
        }

        category.setCategoryName(name);
        category.setDescription(request.getDescription());

        IssueCategory saved = categoryRepository.save(category);
        return CategoryResponse.fromEntity(saved);
    }

    @Transactional
    public void deleteCategory(Long id) {
        if (!categoryRepository.existsById(id)) {
            throw new ResourceNotFoundException("Category not found with id: " + id);
        }
        categoryRepository.deleteById(id);
    }
}
