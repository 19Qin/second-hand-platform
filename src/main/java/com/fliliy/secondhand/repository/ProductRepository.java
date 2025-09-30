package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {
    
    /**
     * 根据状态查找商品（不包含软删除）
     */
    @Query("SELECT p FROM Product p WHERE p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByStatus(@Param("status") Product.ProductStatus status, Pageable pageable);
    
    /**
     * 根据分类查找商品
     */
    @Query("SELECT p FROM Product p WHERE p.categoryId = :categoryId AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByCategoryIdAndStatus(@Param("categoryId") Integer categoryId, 
                                           @Param("status") Product.ProductStatus status, 
                                           Pageable pageable);
    
    /**
     * 根据分类列表查找商品（包含子分类）
     */
    @Query("SELECT p FROM Product p WHERE p.categoryId IN :categoryIds AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByCategoryIdsAndStatus(@Param("categoryIds") List<Integer> categoryIds, 
                                            @Param("status") Product.ProductStatus status, 
                                            Pageable pageable);
    
    /**
     * 根据卖家查找商品
     */
    @Query("SELECT p FROM Product p WHERE p.sellerId = :sellerId AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findBySellerIdAndStatus(@Param("sellerId") Long sellerId, 
                                         @Param("status") Product.ProductStatus status, 
                                         Pageable pageable);
    
    /**
     * 全文搜索商品（标题和描述）
     */
    @Query(value = "SELECT * FROM products p WHERE MATCH(p.title, p.description) AGAINST(?1 IN NATURAL LANGUAGE MODE) " +
                   "AND p.status = ?2 AND p.deleted_at IS NULL", 
           nativeQuery = true)
    Page<Product> searchByKeyword(String keyword, String status, Pageable pageable);
    
    /**
     * 关键词模糊搜索（备用方案，不依赖全文索引）
     */
    @Query("SELECT p FROM Product p WHERE (p.title LIKE %:keyword% OR p.description LIKE %:keyword%) " +
           "AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> searchByKeywordFallback(@Param("keyword") String keyword, 
                                         @Param("status") Product.ProductStatus status, 
                                         Pageable pageable);
    
    /**
     * 价格区间查询
     */
    @Query("SELECT p FROM Product p WHERE p.price BETWEEN :minPrice AND :maxPrice " +
           "AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByPriceBetweenAndStatus(@Param("minPrice") BigDecimal minPrice, 
                                             @Param("maxPrice") BigDecimal maxPrice, 
                                             @Param("status") Product.ProductStatus status, 
                                             Pageable pageable);
    
    /**
     * 地区查询
     */
    @Query("SELECT p FROM Product p WHERE p.province = :province AND p.city = :city " +
           "AND (:district IS NULL OR p.district = :district) " +
           "AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByLocationAndStatus(@Param("province") String province, 
                                         @Param("city") String city, 
                                         @Param("district") String district, 
                                         @Param("status") Product.ProductStatus status, 
                                         Pageable pageable);
    
    /**
     * 附近商品查询（基于经纬度，使用Haversine公式计算距离）
     */
    @Query(value = "SELECT *, " +
                   "(6371 * acos(cos(radians(?2)) * cos(radians(latitude)) * " +
                   "cos(radians(longitude) - radians(?1)) + sin(radians(?2)) * sin(radians(latitude)))) AS distance " +
                   "FROM products " +
                   "WHERE longitude IS NOT NULL AND latitude IS NOT NULL " +
                   "AND status = ?4 AND deleted_at IS NULL " +
                   "HAVING distance <= ?3 " +
                   "ORDER BY distance", 
           nativeQuery = true)
    List<Product> findNearbyProducts(BigDecimal longitude, BigDecimal latitude, 
                                    Integer radiusKm, String status, Pageable pageable);
    
    /**
     * 商品状况查询
     */
    @Query("SELECT p FROM Product p WHERE p.productCondition = :condition " +
           "AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByConditionAndStatus(@Param("condition") Product.ConditionType condition, 
                                          @Param("status") Product.ProductStatus status, 
                                          Pageable pageable);
    
    /**
     * 保修商品查询
     */
    @Query("SELECT p FROM Product p WHERE p.hasWarranty = :hasWarranty " +
           "AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findByWarrantyAndStatus(@Param("hasWarranty") Boolean hasWarranty, 
                                         @Param("status") Product.ProductStatus status, 
                                         Pageable pageable);
    
    /**
     * 推广商品查询
     */
    @Query("SELECT p FROM Product p WHERE p.isPromoted = true " +
           "AND p.promotedExpiresAt > CURRENT_TIMESTAMP " +
           "AND p.status = :status AND p.deletedAt IS NULL")
    Page<Product> findPromotedProducts(@Param("status") Product.ProductStatus status, Pageable pageable);
    
    /**
     * 获取商品详情（包含软删除检查）
     */
    @Query("SELECT p FROM Product p WHERE p.id = :id AND p.deletedAt IS NULL")
    Optional<Product> findByIdAndNotDeleted(@Param("id") Long id);
    
    /**
     * 增加浏览次数
     */
    @Modifying
    @Query("UPDATE Product p SET p.viewCount = p.viewCount + 1 WHERE p.id = :id")
    void incrementViewCount(@Param("id") Long id);
    
    /**
     * 更新收藏次数
     */
    @Modifying
    @Query("UPDATE Product p SET p.favoriteCount = p.favoriteCount + :increment WHERE p.id = :id")
    void updateFavoriteCount(@Param("id") Long id, @Param("increment") int increment);
    
    /**
     * 更新聊天次数
     */
    @Modifying
    @Query("UPDATE Product p SET p.chatCount = p.chatCount + 1 WHERE p.id = :id")
    void incrementChatCount(@Param("id") Long id);
    
    /**
     * 软删除商品
     */
    @Modifying
    @Query("UPDATE Product p SET p.deletedAt = CURRENT_TIMESTAMP WHERE p.id = :id")
    void softDeleteById(@Param("id") Long id);
    
    /**
     * 更新商品状态
     */
    @Modifying
    @Query("UPDATE Product p SET p.status = :status WHERE p.id = :id")
    void updateStatus(@Param("id") Long id, @Param("status") Product.ProductStatus status);
    
    /**
     * 获取相关商品推荐（同分类，不同商品）
     */
    @Query("SELECT p FROM Product p WHERE p.categoryId = :categoryId AND p.id != :productId " +
           "AND p.status = 'ACTIVE' AND p.deletedAt IS NULL " +
           "ORDER BY p.viewCount DESC")
    List<Product> findRelatedProducts(@Param("categoryId") Integer categoryId, 
                                     @Param("productId") Long productId, 
                                     Pageable pageable);
    
    /**
     * 统计用户发布的商品数量
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE p.sellerId = :sellerId " +
           "AND (:status IS NULL OR p.status = :status) AND p.deletedAt IS NULL")
    Long countBySellerIdAndStatus(@Param("sellerId") Long sellerId, 
                                 @Param("status") Product.ProductStatus status);
    
    /**
     * 获取热门商品（按浏览量排序）
     */
    @Query("SELECT p FROM Product p WHERE p.status = 'ACTIVE' AND p.deletedAt IS NULL " +
           "ORDER BY p.viewCount DESC")
    Page<Product> findPopularProducts(Pageable pageable);
    
    /**
     * 获取打折商品（有原价的商品）
     */
    @Query("SELECT p FROM Product p WHERE p.originalPrice IS NOT NULL " +
           "AND p.price < p.originalPrice AND p.status = 'ACTIVE' AND p.deletedAt IS NULL")
    Page<Product> findDiscountProducts(Pageable pageable);
    
    /**
     * 查询用户发布的商品（按发布时间倒序）
     */
    Page<Product> findBySellerIdAndDeletedAtIsNullOrderByCreatedAtDesc(Long sellerId, Pageable pageable);
    
    /**
     * 查询用户发布的商品（支持自定义排序）
     */
    Page<Product> findBySellerIdAndDeletedAtIsNull(Long sellerId, Pageable pageable);
    
    /**
     * 查询用户指定状态的商品（支持自定义排序）
     */
    Page<Product> findBySellerIdAndStatusAndDeletedAtIsNull(Long sellerId, Product.ProductStatus status, Pageable pageable);
    
    /**
     * 统计用户发布的商品总数
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE p.sellerId = :userId AND p.deletedAt IS NULL")
    Long countByUserId(@Param("userId") Long userId);
    
    /**
     * 统计用户指定状态的商品数量
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE p.sellerId = :userId AND p.status = :status AND p.deletedAt IS NULL")
    Long countByUserIdAndStatus(@Param("userId") Long userId, @Param("status") Product.ProductStatus status);
}