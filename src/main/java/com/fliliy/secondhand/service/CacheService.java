package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.response.ProductDetailResponse;
import com.fliliy.secondhand.dto.response.UserProfileResponse;
import com.fliliy.secondhand.entity.Category;
import com.fliliy.secondhand.entity.Product;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 统一缓存服务
 * 负责管理所有核心数据的Redis缓存
 *
 * 缓存策略:
 * - 商品详情: 5分钟 (变化较频繁)
 * - 用户信息: 30分钟 (较稳定)
 * - 分类树: 6小时 (很少变化)
 *
 * @author Fliliy Team
 * @since 2025-10-01
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CacheService {

    private final ProductService productService;
    private final UserService userService;
    private final CategoryService categoryService;

    /**
     * 获取商品详情 (带缓存)
     * 缓存时间: 5分钟
     */
    @Cacheable(value = "products", key = "'detail:' + #productId", unless = "#result == null")
    public ProductDetailResponse getProductDetailCached(Long productId, Long currentUserId) {
        log.debug("缓存未命中,查询商品详情: productId={}", productId);
        return productService.getProductDetail(productId, currentUserId);
    }

    /**
     * 更新商品缓存
     */
    @CachePut(value = "products", key = "'detail:' + #productId")
    public ProductDetailResponse updateProductCache(Long productId, Long currentUserId) {
        log.debug("更新商品缓存: productId={}", productId);
        return productService.getProductDetail(productId, currentUserId);
    }

    /**
     * 删除商品缓存
     */
    @CacheEvict(value = "products", key = "'detail:' + #productId")
    public void evictProductCache(Long productId) {
        log.debug("删除商品缓存: productId={}", productId);
    }

    /**
     * 获取用户信息 (带缓存)
     * 缓存时间: 30分钟
     */
    @Cacheable(value = "users", key = "'profile:' + #userId", unless = "#result == null")
    public UserProfileResponse getUserProfileCached(Long userId) {
        log.debug("缓存未命中,查询用户信息: userId={}", userId);
        return userService.getUserProfile(userId);
    }

    /**
     * 更新用户缓存
     */
    @CachePut(value = "users", key = "'profile:' + #userId")
    public UserProfileResponse updateUserCache(Long userId) {
        log.debug("更新用户缓存: userId={}", userId);
        return userService.getUserProfile(userId);
    }

    /**
     * 删除用户缓存
     */
    @CacheEvict(value = "users", key = "'profile:' + #userId")
    public void evictUserCache(Long userId) {
        log.debug("删除用户缓存: userId={}", userId);
    }

    /**
     * 获取分类树 (带缓存)
     * 缓存时间: 6小时
     */
    @Cacheable(value = "categories", key = "'tree'")
    public List<Category> getCategoryTreeCached() {
        log.debug("缓存未命中,查询分类树");
        return categoryService.getCategoryTree();
    }

    /**
     * 刷新分类树缓存
     */
    @CacheEvict(value = "categories", key = "'tree'")
    public void refreshCategoryTreeCache() {
        log.info("刷新分类树缓存");
    }

    /**
     * 批量删除商品缓存
     */
    public void evictProductCacheBatch(List<Long> productIds) {
        log.debug("批量删除商品缓存: count={}", productIds.size());
        productIds.forEach(this::evictProductCache);
    }

    /**
     * 清除所有商品缓存
     */
    @CacheEvict(value = "products", allEntries = true)
    public void evictAllProductsCache() {
        log.info("清除所有商品缓存");
    }

    /**
     * 清除所有用户缓存
     */
    @CacheEvict(value = "users", allEntries = true)
    public void evictAllUsersCache() {
        log.info("清除所有用户缓存");
    }

    /**
     * 清除所有缓存
     */
    @CacheEvict(value = {"products", "users", "categories"}, allEntries = true)
    public void evictAllCache() {
        log.info("清除所有缓存");
    }
}
