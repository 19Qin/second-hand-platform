package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.request.PublishProductRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductDetailResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.dto.response.UploadResponse;
import com.fliliy.secondhand.service.FileService;
import com.fliliy.secondhand.service.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/products")
@RequiredArgsConstructor
@Slf4j
public class ProductController {
    
    private final ProductService productService;
    private final FileService fileService;
    
    /**
     * 上传商品图片
     */
    @PostMapping("/upload")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<UploadResponse> uploadImage(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            UploadResponse response = fileService.uploadProductImage(file);
            return ApiResponse.success("上传成功", response);
        } catch (Exception e) {
            log.error("Upload product image failed", e);
            return ApiResponse.error("图片上传失败: " + e.getMessage());
        }
    }
    
    /**
     * 发布商品
     */
    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Map<String, Object>> publishProduct(
            @Valid @RequestBody PublishProductRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long sellerId = Long.valueOf(userDetails.getUsername());
            Long productId = productService.publishProduct(request, sellerId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("productId", productId.toString());
            response.put("status", "ACTIVE");
            response.put("publishTime", LocalDateTime.now());
            
            return ApiResponse.success("发布成功", response);
        } catch (Exception e) {
            log.error("Publish product failed", e);
            return ApiResponse.error("商品发布失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取商品列表（主页/搜索/筛选）
     */
    @GetMapping
    public ApiResponse<PagedResponse<ProductSummaryResponse>> getProducts(
            @Valid ProductQueryRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            // 验证价格区间
            if (!request.isPriceRangeValid()) {
                return ApiResponse.error("价格区间设置不正确");
            }
            
            // 验证地理位置参数
            if (!request.isLocationValid()) {
                return ApiResponse.error("地理位置参数不完整");
            }
            
            Long currentUserId = userDetails != null ? Long.valueOf(userDetails.getUsername()) : null;
            PagedResponse<ProductSummaryResponse> response = productService.getProducts(request, currentUserId);
            
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get products failed", e);
            return ApiResponse.error("获取商品列表失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取商品详情
     */
    @GetMapping("/{productId}")
    public ApiResponse<ProductDetailResponse> getProductDetail(
            @PathVariable Long productId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long currentUserId = userDetails != null ? Long.valueOf(userDetails.getUsername()) : null;
            ProductDetailResponse response = productService.getProductDetail(productId, currentUserId);
            
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get product detail failed: productId={}", productId, e);
            return ApiResponse.error("获取商品详情失败: " + e.getMessage());
        }
    }
    
    /**
     * 收藏/取消收藏商品
     */
    @PostMapping("/{productId}/favorite")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Map<String, Object>> toggleFavorite(
            @PathVariable Long productId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            Map<String, Object> result = productService.toggleFavorite(productId, userId);
            
            boolean isFavorited = (Boolean) result.get("isFavorited");
            String message = isFavorited ? "收藏成功" : "取消收藏成功";
            
            return ApiResponse.success(message, result);
        } catch (Exception e) {
            log.error("Toggle favorite failed: productId={}", productId, e);
            return ApiResponse.error("操作失败: " + e.getMessage());
        }
    }
    
    /**
     * 编辑商品
     */
    @PutMapping("/{productId}")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Void> updateProduct(
            @PathVariable Long productId,
            @Valid @RequestBody PublishProductRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long sellerId = Long.valueOf(userDetails.getUsername());
            productService.updateProduct(productId, request, sellerId);
            
            return ApiResponse.success("更新成功", null);
        } catch (Exception e) {
            log.error("Update product failed: productId={}", productId, e);
            return ApiResponse.error("更新商品失败: " + e.getMessage());
        }
    }
    
    /**
     * 删除商品（下架）
     */
    @DeleteMapping("/{productId}")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Map<String, Object>> deleteProduct(
            @PathVariable Long productId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long sellerId = Long.valueOf(userDetails.getUsername());
            productService.deleteProduct(productId, sellerId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("productId", productId.toString());
            response.put("status", "INACTIVE");
            
            return ApiResponse.success("商品已下架", response);
        } catch (Exception e) {
            log.error("Delete product failed: productId={}", productId, e);
            return ApiResponse.error("删除商品失败: " + e.getMessage());
        }
    }
}