package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.ProductFavorite;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ProductFavoriteRepository extends JpaRepository<ProductFavorite, Long> {
    
    /**
     * 检查用户是否收藏了商品
     */
    boolean existsByUserIdAndProductId(Long userId, Long productId);
    
    /**
     * 查找用户对特定商品的收藏记录
     */
    Optional<ProductFavorite> findByUserIdAndProductId(Long userId, Long productId);
    
    /**
     * 获取用户的收藏列表（按收藏时间倒序）
     */
    @Query("SELECT pf FROM ProductFavorite pf WHERE pf.userId = :userId ORDER BY pf.createdAt DESC")
    Page<ProductFavorite> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);
    
    /**
     * 获取用户收藏的在售商品
     */
    @Query("SELECT pf FROM ProductFavorite pf JOIN Product p ON pf.productId = p.id " +
           "WHERE pf.userId = :userId AND p.status = 'ACTIVE' AND p.deletedAt IS NULL " +
           "ORDER BY pf.createdAt DESC")
    Page<ProductFavorite> findUserActiveProductFavorites(@Param("userId") Long userId, Pageable pageable);
    
    /**
     * 统计商品的收藏次数
     */
    Long countByProductId(Long productId);
    
    /**
     * 统计用户的收藏数量
     */
    Long countByUserId(Long userId);
    
    /**
     * 删除用户对商品的收藏
     */
    @Modifying
    @Query("DELETE FROM ProductFavorite pf WHERE pf.userId = :userId AND pf.productId = :productId")
    void deleteByUserIdAndProductId(@Param("userId") Long userId, @Param("productId") Long productId);
    
    /**
     * 批量删除用户收藏（用于用户注销等场景）
     */
    @Modifying
    @Query("DELETE FROM ProductFavorite pf WHERE pf.userId = :userId")
    void deleteByUserId(@Param("userId") Long userId);
    
    /**
     * 批量删除商品收藏（用于商品删除等场景）
     */
    @Modifying
    @Query("DELETE FROM ProductFavorite pf WHERE pf.productId = :productId")
    void deleteByProductId(@Param("productId") Long productId);
    
    /**
     * 获取最受欢迎的商品（按收藏数量排序）
     */
    @Query("SELECT pf.productId, COUNT(pf.productId) as favoriteCount FROM ProductFavorite pf " +
           "GROUP BY pf.productId ORDER BY favoriteCount DESC")
    Page<Object[]> findMostFavoritedProducts(Pageable pageable);
    
    /**
     * 获取用户的收藏商品ID列表（用于批量查询）
     */
    @Query("SELECT pf.productId FROM ProductFavorite pf WHERE pf.userId = :userId")
    java.util.List<Long> findProductIdsByUserId(@Param("userId") Long userId);
}