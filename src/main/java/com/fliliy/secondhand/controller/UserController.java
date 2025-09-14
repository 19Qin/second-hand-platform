package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
@Slf4j
public class UserController {
    
    private final UserService userService;
    
    /**
     * 获取用户收藏的商品列表
     */
    @GetMapping("/favorites")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<PagedResponse<ProductSummaryResponse>> getUserFavorites(
            @Valid ProductQueryRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            PagedResponse<ProductSummaryResponse> response = userService.getUserFavorites(request, userId);
            
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get user favorites failed", e);
            return ApiResponse.error("获取收藏列表失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取用户发布的商品列表
     */
    @GetMapping("/products")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<PagedResponse<ProductSummaryResponse>> getUserProducts(
            @Valid ProductQueryRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            PagedResponse<ProductSummaryResponse> response = userService.getUserProducts(request, userId);
            
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get user products failed", e);
            return ApiResponse.error("获取用户商品失败: " + e.getMessage());
        }
    }
}