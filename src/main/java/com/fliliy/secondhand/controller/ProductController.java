package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.annotation.RateLimit;
import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.request.PublishProductRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductDetailResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.dto.response.UploadResponse;
import com.fliliy.secondhand.service.CacheService;
import com.fliliy.secondhand.service.FileService;
import com.fliliy.secondhand.service.ProductService;
import com.fliliy.secondhand.util.RateLimiter;
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
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/products")
@RequiredArgsConstructor
@Slf4j
public class ProductController {
    
    private final ProductService productService;
    private final FileService fileService;
    private final CacheService cacheService;
    
    /**
     * 上传商品图片
     */
    @PostMapping("/upload")
    @PreAuthorize("hasRole('USER')")
    @RateLimit(key = "uploadProductImage", limitType = RateLimiter.LimitType.USER, maxCount = 20, period = 60, message = "上传过于频繁，请稍后再试")
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
    @RateLimit(key = "publishProduct", limitType = RateLimiter.LimitType.USER, maxCount = 5, period = 60, message = "发布商品过于频繁，请稍后再试")
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
    @RateLimit(key = "searchProducts", limitType = RateLimiter.LimitType.USER, maxCount = 60, period = 60, message = "搜索过于频繁，请稍后再试")
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
     * 获取商品详情 (带缓存)
     */
    @GetMapping("/{productId}")
    public ApiResponse<ProductDetailResponse> getProductDetail(
            @PathVariable Long productId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long currentUserId = userDetails != null ? Long.valueOf(userDetails.getUsername()) : null;
            // 使用缓存服务获取商品详情
            ProductDetailResponse response = cacheService.getProductDetailCached(productId, currentUserId);

            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get product detail failed: productId={}", productId, e);
            return ApiResponse.error("获取商品详情失败: " + e.getMessage());
        }
    }
    
    /**
     * 收藏/取消收藏商品（Toggle方式）
     *
     * 采用Toggle模式的原因：
     * 1. 用户体验更好 - 一个按钮完成收藏和取消收藏
     * 2. 前端实现更简单 - 无需判断状态调用不同接口
     * 3. 行业主流做法 - 淘宝、微信等主流应用都采用此方式
     *
     * 接口会自动判断当前收藏状态：
     * - 未收藏 -> 添加收藏，返回 isFavorited=true
     * - 已收藏 -> 取消收藏，返回 isFavorited=false
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
     * 查询商品收藏状态
     */
    @GetMapping("/{productId}/favorite/status")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Map<String, Object>> getFavoriteStatus(
            @PathVariable Long productId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            boolean isFavorited = productService.isFavorited(productId, userId);

            Map<String, Object> response = new HashMap<>();
            response.put("productId", productId.toString());
            response.put("isFavorited", isFavorited);

            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get favorite status failed: productId={}", productId, e);
            return ApiResponse.error("获取收藏状态失败: " + e.getMessage());
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

            // 清除商品缓存
            cacheService.evictProductCache(productId);

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

            // 清除商品缓存
            cacheService.evictProductCache(productId);

            Map<String, Object> response = new HashMap<>();
            response.put("productId", productId.toString());
            response.put("status", "INACTIVE");

            return ApiResponse.success("商品已下架", response);
        } catch (Exception e) {
            log.error("Delete product failed: productId={}", productId, e);
            return ApiResponse.error("删除商品失败: " + e.getMessage());
        }
    }

    /**
     * 获取相似商品推荐
     */
    @GetMapping("/{productId}/similar")
    public ApiResponse<Map<String, Object>> getSimilarProducts(
            @PathVariable Long productId,
            @RequestParam(defaultValue = "5") int limit,
            @AuthenticationPrincipal(errorOnInvalidType = false) UserDetails userDetails) {
        try {
            Long currentUserId = userDetails != null ? Long.valueOf(userDetails.getUsername()) : null;

            List<ProductSummaryResponse> similarProducts = productService.getSimilarProducts(productId, limit, currentUserId);

            Map<String, Object> response = new HashMap<>();
            response.put("products", similarProducts);
            response.put("total", similarProducts.size());

            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get similar products failed: productId={}", productId, e);
            return ApiResponse.error("获取相似商品失败: " + e.getMessage());
        }
    }
}