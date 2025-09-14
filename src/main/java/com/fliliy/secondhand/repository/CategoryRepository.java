package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Integer> {
    
    /**
     * 查找顶级分类（按排序顺序）
     */
    List<Category> findByParentIdAndIsActiveOrderBySortOrder(Integer parentId, Boolean isActive);
    
    /**
     * 查找子分类（按排序顺序）
     */
    List<Category> findByParentIdOrderBySortOrder(Integer parentId);
    
    /**
     * 检查分类是否存在且启用
     */
    boolean existsByIdAndIsActive(Integer id, Boolean isActive);
    
    /**
     * 获取分类树结构（递归查询）
     */
    @Query("SELECT c FROM Category c WHERE c.isActive = true ORDER BY c.parentId, c.sortOrder")
    List<Category> findAllActiveCategories();
    
    /**
     * 根据父级ID获取所有子分类ID（用于商品查询时包含子分类）
     */
    @Query("SELECT c.id FROM Category c WHERE c.parentId = :parentId AND c.isActive = true")
    List<Integer> findChildCategoryIds(@Param("parentId") Integer parentId);
    
    /**
     * 获取分类路径（如：电子产品 > 手机）
     */
    @Query("SELECT CASE WHEN pc.name IS NULL THEN c.name " +
           "ELSE CONCAT(pc.name, ' > ', c.name) END " +
           "FROM Category c LEFT JOIN Category pc ON c.parentId = pc.id " +
           "WHERE c.id = :categoryId")
    String getCategoryPath(@Param("categoryId") Integer categoryId);
    
    /**
     * 更新分类商品数量
     */
    @Modifying
    @Query("UPDATE Category c SET c.productCount = " +
           "(SELECT COUNT(p) FROM Product p WHERE p.categoryId = c.id AND p.status = 'ACTIVE' AND p.deletedAt IS NULL) " +
           "WHERE c.id = :categoryId")
    void updateProductCount(@Param("categoryId") Integer categoryId);
}