package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.request.UpdateProfileRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.dto.response.UserProfileResponse;
import com.fliliy.secondhand.entity.Product;
import com.fliliy.secondhand.entity.ProductFavorite;
import com.fliliy.secondhand.entity.User;
import com.fliliy.secondhand.repository.ProductFavoriteRepository;
import com.fliliy.secondhand.repository.ProductRepository;
import com.fliliy.secondhand.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {
    
    private final ProductFavoriteRepository productFavoriteRepository;
    private final ProductService productService;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    
    /**
     * 获取用户收藏的商品列表
     */
    public PagedResponse<ProductSummaryResponse> getUserFavorites(ProductQueryRequest request, Long userId) {
        log.info("Getting user favorites: userId={}, page={}, size={}", 
                userId, request.getPage(), request.getSize());
        
        // 创建分页对象
        Pageable pageable = PageRequest.of(request.getPage() - 1, request.getSize());
        
        // 查询用户收藏的商品（只查询在售商品）
        Page<ProductFavorite> favoritePage = productFavoriteRepository
                .findUserActiveProductFavorites(userId, pageable);
        
        // 提取商品ID列表
        List<Long> productIds = favoritePage.getContent().stream()
                .map(ProductFavorite::getProductId)
                .collect(Collectors.toList());
        
        // 如果没有收藏商品，返回空列表
        if (productIds.isEmpty()) {
            return PagedResponse.<ProductSummaryResponse>builder()
                    .content(Collections.emptyList())
                    .pagination(PagedResponse.PaginationInfo.builder()
                            .page(request.getPage())
                            .size(request.getSize())
                            .total(0L)
                            .totalPages(0)
                            .hasNext(false)
                            .hasPrevious(request.getPage() > 1)
                            .isFirst(request.getPage() == 1)
                            .isLast(true)
                            .build())
                    .build();
        }
        
        // 批量查询商品详情并转换为ProductSummaryResponse
        List<ProductSummaryResponse> favoriteProducts = productService
                .getProductSummariesByIds(productIds, userId);
        
        // 构建分页响应
        return PagedResponse.<ProductSummaryResponse>builder()
                .content(favoriteProducts)
                .pagination(PagedResponse.PaginationInfo.builder()
                        .page(request.getPage())
                        .size(request.getSize())
                        .total(favoritePage.getTotalElements())
                        .totalPages(favoritePage.getTotalPages())
                        .hasNext(favoritePage.hasNext())
                        .hasPrevious(favoritePage.hasPrevious())
                        .isFirst(favoritePage.isFirst())
                        .isLast(favoritePage.isLast())
                        .build())
                .build();
    }
    
    /**
     * 获取用户发布的商品列表
     */
    public PagedResponse<ProductSummaryResponse> getUserProducts(ProductQueryRequest request, Long userId) {
        log.info("Getting user products: userId={}, page={}, size={}", 
                userId, request.getPage(), request.getSize());
        
        // 设置查询条件为当前用户发布的商品
        ProductQueryRequest userProductRequest = new ProductQueryRequest();
        userProductRequest.setPage(request.getPage());
        userProductRequest.setSize(request.getSize());
        userProductRequest.setSort(request.getSort());
        userProductRequest.setKeyword(request.getKeyword());
        userProductRequest.setCategoryId(request.getCategoryId());
        userProductRequest.setMinPrice(request.getMinPrice());
        userProductRequest.setMaxPrice(request.getMaxPrice());
        userProductRequest.setCondition(request.getCondition());
        
        // 使用ProductService查询，但限制为当前用户的商品
        return productService.getUserProducts(userProductRequest, userId);
    }
    
    /**
     * 根据ID获取用户信息
     */
    public User getUserById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
    }
    
    /**
     * 获取用户资料详情
     */
    public UserProfileResponse getUserProfile(Long userId) {
        log.info("Getting user profile: userId={}", userId);
        
        User user = getUserById(userId);
        
        UserProfileResponse response = new UserProfileResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setMobile(maskMobile(user.getMobile()));
        response.setEmail(maskEmail(user.getEmail()));
        response.setAvatar(user.getAvatar());
        response.setGender(user.getGender());
        response.setBirthday(user.getBirthday());
        response.setLocation(user.getLocation());
        response.setBio(user.getBio());
        response.setVerified(user.getVerified());
        response.setRegisteredAt(user.getCreatedAt());
        response.setLastLoginAt(user.getLastLoginAt());
        
        // 设置用户统计数据
        UserProfileResponse.UserStatsResponse stats = calculateUserStats(userId);
        response.setStats(stats);
        
        // 设置用户偏好（暂时使用默认值）
        UserProfileResponse.UserPreferencesResponse preferences = new UserProfileResponse.UserPreferencesResponse();
        response.setPreferences(preferences);
        
        return response;
    }
    
    /**
     * 更新用户资料
     */
    public void updateUserProfile(Long userId, UpdateProfileRequest request) {
        log.info("Updating user profile: userId={}", userId);
        
        User user = getUserById(userId);
        
        // 更新用户信息
        if (request.getUsername() != null) {
            user.setUsername(request.getUsername());
        }
        if (request.getAvatar() != null) {
            user.setAvatar(request.getAvatar());
        }
        if (request.getGender() != null) {
            user.setGender(request.getGender());
        }
        if (request.getBirthday() != null) {
            user.setBirthday(request.getBirthday());
        }
        if (request.getLocation() != null) {
            user.setLocation(request.getLocation());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        if (request.getEmail() != null) {
            user.setEmail(request.getEmail());
        }
        
        userRepository.save(user);
        log.info("User profile updated successfully: userId={}", userId);
    }
    
    /**
     * 手机号脱敏
     */
    private String maskMobile(String mobile) {
        if (mobile == null || mobile.length() < 7) {
            return mobile;
        }
        if (mobile.length() == 10) {
            // 澳洲手机号 0435497013 -> 043****013
            return mobile.substring(0, 3) + "****" + mobile.substring(7);
        } else if (mobile.length() == 11) {
            // 中国手机号 13800138000 -> 138****8000
            return mobile.substring(0, 3) + "****" + mobile.substring(7);
        }
        return mobile;
    }
    
    /**
     * 邮箱脱敏
     */
    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return email;
        }
        String[] parts = email.split("@");
        if (parts[0].length() <= 3) {
            return parts[0].substring(0, 1) + "***@" + parts[1];
        }
        return parts[0].substring(0, 3) + "***@" + parts[1];
    }
    
    /**
     * 计算用户统计数据
     */
    private UserProfileResponse.UserStatsResponse calculateUserStats(Long userId) {
        UserProfileResponse.UserStatsResponse stats = new UserProfileResponse.UserStatsResponse();
        
        // 查询用户发布的商品总数
        Long publishedCount = productRepository.countByUserId(userId);
        stats.setPublishedCount(publishedCount);
        
        // 查询在售商品数
        Long activeCount = productRepository.countByUserIdAndStatus(userId, Product.ProductStatus.ACTIVE);
        stats.setActiveCount(activeCount);
        
        // 查询已售出商品数
        Long soldCount = productRepository.countByUserIdAndStatus(userId, Product.ProductStatus.SOLD);
        stats.setSoldCount(soldCount);
        
        // 查询收藏数量
        Long favoriteCount = productFavoriteRepository.countByUserId(userId);
        stats.setFavoriteCount(favoriteCount);
        
        // TODO: 后续添加购买数、聊天数等统计
        stats.setBoughtCount(0L);
        stats.setChatCount(0L);
        
        return stats;
    }
}