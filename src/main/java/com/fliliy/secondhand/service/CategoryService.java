package com.fliliy.secondhand.service;

import com.fliliy.secondhand.entity.Category;
import com.fliliy.secondhand.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryService {
    
    private final CategoryRepository categoryRepository;
    
    /**
     * 获取分类树结构
     */
    @Cacheable(value = "categories", key = "'tree'")
    public List<Category> getCategoryTree() {
        List<Category> allCategories = categoryRepository.findAllActiveCategories();
        return buildCategoryTree(allCategories);
    }
    
    /**
     * 获取顶级分类列表
     */
    @Cacheable(value = "categories", key = "'top'")
    public List<Category> getTopCategories() {
        return categoryRepository.findByParentIdAndIsActiveOrderBySortOrder(0, true);
    }
    
    /**
     * 获取子分类列表
     */
    @Cacheable(value = "categories", key = "'children_' + #parentId")
    public List<Category> getChildCategories(Integer parentId) {
        return categoryRepository.findByParentIdOrderBySortOrder(parentId);
    }
    
    /**
     * 根据ID获取分类信息
     */
    @Cacheable(value = "categories", key = "#categoryId")
    public Optional<Category> getCategoryById(Integer categoryId) {
        return categoryRepository.findById(categoryId);
    }
    
    /**
     * 检查分类是否有效
     */
    public boolean isCategoryValid(Integer categoryId) {
        return categoryRepository.existsByIdAndIsActive(categoryId, true);
    }
    
    /**
     * 获取分类路径（如：电子产品 > 手机）
     */
    @Cacheable(value = "categories", key = "'path_' + #categoryId")
    public String getCategoryPath(Integer categoryId) {
        return categoryRepository.getCategoryPath(categoryId);
    }
    
    /**
     * 获取包含所有子分类的分类ID列表（用于商品查询）
     */
    public List<Integer> getCategoryIdsIncludeChildren(Integer categoryId) {
        List<Integer> categoryIds = new ArrayList<>();
        categoryIds.add(categoryId);
        
        // 添加子分类ID
        List<Integer> childIds = categoryRepository.findChildCategoryIds(categoryId);
        categoryIds.addAll(childIds);
        
        return categoryIds;
    }
    
    /**
     * 更新分类商品数量
     */
    @Transactional
    public void updateCategoryProductCount(Integer categoryId) {
        categoryRepository.updateProductCount(categoryId);
        log.info("Updated product count for category: {}", categoryId);
    }
    
    /**
     * 构建分类树结构
     */
    private List<Category> buildCategoryTree(List<Category> allCategories) {
        Map<Integer, Category> categoryMap = allCategories.stream()
                .collect(Collectors.toMap(Category::getId, category -> category));
        
        // 找到所有顶级分类
        List<Category> rootCategories = allCategories.stream()
                .filter(category -> category.getParentId() == 0)
                .collect(Collectors.toList());
        
        // 为每个分类设置子分类
        for (Category category : allCategories) {
            if (category.getParentId() != 0) {
                Category parent = categoryMap.get(category.getParentId());
                if (parent != null) {
                    if (parent.getChildren() == null) {
                        parent.setChildren(new ArrayList<>());
                    }
                    parent.getChildren().add(category);
                }
            }
        }
        
        // 对子分类进行排序
        sortCategoryTree(rootCategories);
        
        return rootCategories;
    }
    
    /**
     * 递归排序分类树
     */
    private void sortCategoryTree(List<Category> categories) {
        if (categories == null) return;
        
        categories.sort(Comparator.comparing(Category::getSortOrder));
        
        for (Category category : categories) {
            if (category.getChildren() != null) {
                sortCategoryTree(category.getChildren());
            }
        }
    }
}