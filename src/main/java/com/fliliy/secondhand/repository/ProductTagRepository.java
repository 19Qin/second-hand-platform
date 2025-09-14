package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.ProductTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductTagRepository extends JpaRepository<ProductTag, Integer> {
    
    /**
     * 根据商品ID查找标签
     */
    List<ProductTag> findByProductId(Long productId);
    
    /**
     * 根据商品ID查找标签名称列表
     */
    @Query("SELECT pt.tagName FROM ProductTag pt WHERE pt.productId = :productId")
    List<String> findTagNamesByProductId(@Param("productId") Long productId);
    
    /**
     * 批量删除商品标签
     */
    @Modifying
    @Query("DELETE FROM ProductTag pt WHERE pt.productId = :productId")
    void deleteByProductId(@Param("productId") Long productId);
    
    /**
     * 删除指定标签
     */
    @Modifying
    @Query("DELETE FROM ProductTag pt WHERE pt.productId = :productId AND pt.tagName = :tagName")
    void deleteByProductIdAndTagName(@Param("productId") Long productId, @Param("tagName") String tagName);
    
    /**
     * 检查标签是否存在
     */
    boolean existsByProductIdAndTagName(Long productId, String tagName);
    
    /**
     * 获取热门标签（使用频率最高的标签）
     */
    @Query("SELECT pt.tagName, COUNT(pt.tagName) as tagCount FROM ProductTag pt " +
           "GROUP BY pt.tagName ORDER BY tagCount DESC")
    List<Object[]> findPopularTags(@Param("limit") int limit);
    
    /**
     * 根据标签名查找相关商品ID
     */
    @Query("SELECT DISTINCT pt.productId FROM ProductTag pt WHERE pt.tagName = :tagName")
    List<Long> findProductIdsByTagName(@Param("tagName") String tagName);
    
    /**
     * 批量插入标签
     */
    @Modifying
    @Query(value = "INSERT INTO product_tags (product_id, tag_name, created_at) " +
                   "VALUES (:productId, :tagName, NOW())", 
           nativeQuery = true)
    void batchInsert(@Param("productId") Long productId, @Param("tagName") String tagName);
}