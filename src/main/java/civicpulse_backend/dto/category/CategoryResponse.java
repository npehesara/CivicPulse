package civicpulse_backend.dto.category;

import civicpulse_backend.entity.IssueCategory;

public class CategoryResponse {

    private Long categoryId;
    private String categoryName;
    private String description;

    public CategoryResponse() {
    }

    public static CategoryResponse fromEntity(IssueCategory category) {
        if (category == null) return null;
        CategoryResponse response = new CategoryResponse();
        response.setCategoryId(category.getCategoryId());
        response.setCategoryName(category.getCategoryName());
        response.setDescription(category.getDescription());
        return response;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
