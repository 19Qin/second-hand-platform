package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.ProductSearchRequest;
import com.fliliy.secondhand.dto.response.ProductSearchResponse;
import com.fliliy.secondhand.service.ProductSearchService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;

/**
 * 商品搜索控制器
 */
@Slf4j
@RestController
@RequestMapping("/products/search")
@RequiredArgsConstructor
public class ProductSearchController {

    private final ProductSearchService productSearchService;

    /**
     * 搜索商品
     */
    @GetMapping
    public ApiResponse<ProductSearchResponse> searchProducts(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) String province,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String sortOrder,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer size
    ) {
        log.info("接收商品搜索请求 - keyword: {}, categoryId: {}, page: {}, size: {}",
            keyword, categoryId, page, size);

        try {
            // 构建搜索请求
            ProductSearchRequest request = new ProductSearchRequest();
            request.setKeyword(keyword);
            request.setCategoryId(categoryId);
            request.setProvince(province);
            request.setCity(city);
            request.setMinPrice(minPrice);
            request.setMaxPrice(maxPrice);
            request.setStatus(status);
            request.setSortBy(sortBy);
            request.setSortOrder(sortOrder);
            request.setPage(page);
            request.setSize(size);

            ProductSearchResponse response = productSearchService.searchProducts(request);
            return ApiResponse.success(response);
        } catch (Exception e) {
            log.error("搜索失败", e);
            return ApiResponse.error("搜索失败: " + e.getMessage());
        }
    }

    /**
     * 搜索建议
     */
    @GetMapping("/suggest")
    public ApiResponse<List<String>> searchSuggest(
            @RequestParam String prefix,
            @RequestParam(required = false, defaultValue = "10") Integer size
    ) {
        log.info("接收搜索建议请求 - prefix: {}, size: {}", prefix, size);

        if (prefix == null || prefix.trim().isEmpty()) {
            return ApiResponse.success("搜索前缀不能为空", Collections.emptyList());
        }

        List<String> suggestions = productSearchService.searchSuggest(prefix, size);
        return ApiResponse.success(suggestions);
    }
}
