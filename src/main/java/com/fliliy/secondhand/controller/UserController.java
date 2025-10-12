package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.request.UpdateProfileRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.dto.response.UploadResponse;
import com.fliliy.secondhand.dto.response.UserProfileResponse;
import com.fliliy.secondhand.service.CacheService;
import com.fliliy.secondhand.service.FileService;
import com.fliliy.secondhand.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
@Slf4j
public class UserController {
    
    private final UserService userService;
    private final FileService fileService;
    private final CacheService cacheService;

    /**
     * 获取用户资料详情 (带缓存)
     */
    @GetMapping("/profile")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<UserProfileResponse> getUserProfile(@AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            // 使用缓存服务获取用户资料
            UserProfileResponse response = cacheService.getUserProfileCached(userId);

            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get user profile failed", e);
            return ApiResponse.error("获取用户资料失败: " + e.getMessage());
        }
    }
    
    /**
     * 更新用户资料
     */
    @PutMapping("/profile")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Void> updateUserProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            userService.updateUserProfile(userId, request);

            // 清除用户缓存
            cacheService.evictUserCache(userId);

            return new ApiResponse<>(200, "更新成功", null);
        } catch (Exception e) {
            log.error("Update user profile failed", e);
            return ApiResponse.error("更新用户资料失败: " + e.getMessage());
        }
    }
    
    /**
     * 上传头像
     */
    @PostMapping("/avatar/upload")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<UploadResponse> uploadAvatar(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());

            // 上传文件
            UploadResponse uploadResponse = fileService.uploadAvatarFile(file);

            // 更新用户头像
            UpdateProfileRequest updateRequest = new UpdateProfileRequest();
            updateRequest.setAvatar(uploadResponse.getUrl());
            userService.updateUserProfile(userId, updateRequest);

            // 清除用户缓存
            cacheService.evictUserCache(userId);

            return ApiResponse.success("头像上传成功", uploadResponse);
        } catch (Exception e) {
            log.error("Upload avatar failed", e);
            return ApiResponse.error("头像上传失败: " + e.getMessage());
        }
    }
    
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

    /**
     * 获取其他用户的公开资料
     */
    @GetMapping("/{userId}/profile")
    public ApiResponse<UserProfileResponse> getPublicUserProfile(@PathVariable Long userId) {
        try {
            UserProfileResponse response = userService.getPublicUserProfile(userId);
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get public user profile failed: userId={}", userId, e);
            return ApiResponse.error("获取用户资料失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户的评价列表
     */
    @GetMapping("/{userId}/ratings")
    public ApiResponse<PagedResponse> getUserRatings(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            PagedResponse response = userService.getUserRatings(userId, page, size);
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get user ratings failed: userId={}", userId, e);
            return ApiResponse.error("获取用户评价失败: " + e.getMessage());
        }
    }
}