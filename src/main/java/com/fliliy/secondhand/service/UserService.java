package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.entity.ProductFavorite;
import com.fliliy.secondhand.entity.User;
import com.fliliy.secondhand.repository.ProductFavoriteRepository;
import com.fliliy.secondhand.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

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
}