package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.ProductImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductImageRepository extends JpaRepository<ProductImage, Long> {
    
    /**
     * 根据商品ID查找图片（按排序顺序）
     */
    List<ProductImage> findByProductIdOrderBySortOrder(Long productId);
    
    /**
     * 获取商品主图（排序为0的图片）
     */
    Optional<ProductImage> findByProductIdAndSortOrder(Long productId, Integer sortOrder);
    
    /**
     * 获取商品主图URL
     */
    @Query("SELECT pi.imageUrl FROM ProductImage pi WHERE pi.productId = :productId AND pi.sortOrder = 0")
    Optional<String> findMainImageUrl(@Param("productId") Long productId);
    
    /**
     * 统计商品图片数量
     */
    Long countByProductId(Long productId);
    
    /**
     * 批量删除商品图片
     */
    @Modifying
    @Query("DELETE FROM ProductImage pi WHERE pi.productId = :productId")
    void deleteByProductId(@Param("productId") Long productId);
    
    /**
     * 删除指定排序的图片
     */
    @Modifying
    @Query("DELETE FROM ProductImage pi WHERE pi.productId = :productId AND pi.sortOrder = :sortOrder")
    void deleteByProductIdAndSortOrder(@Param("productId") Long productId, @Param("sortOrder") Integer sortOrder);
    
    /**
     * 更新图片排序（用于图片重新排序）
     */
    @Modifying
    @Query("UPDATE ProductImage pi SET pi.sortOrder = :newSortOrder WHERE pi.id = :id")
    void updateSortOrder(@Param("id") Long id, @Param("newSortOrder") Integer newSortOrder);
    
    /**
     * 批量插入图片（原生SQL，提高性能）
     */
    @Modifying
    @Query(value = "INSERT INTO product_images (product_id, image_url, thumbnail_url, sort_order, upload_time) " +
                   "VALUES (:productId, :imageUrl, :thumbnailUrl, :sortOrder, NOW())", 
           nativeQuery = true)
    void batchInsert(@Param("productId") Long productId, 
                    @Param("imageUrl") String imageUrl, 
                    @Param("thumbnailUrl") String thumbnailUrl, 
                    @Param("sortOrder") Integer sortOrder);
}