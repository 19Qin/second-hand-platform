package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.entity.Category;
import com.fliliy.secondhand.service.CategoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
@Slf4j
public class CategoryController {
    
    private final CategoryService categoryService;
    
    /**
     * 获取商品分类树结构
     */
    @GetMapping
    public ApiResponse<List<Category>> getCategories() {
        try {
            List<Category> categories = categoryService.getCategoryTree();
            return ApiResponse.success("获取成功", categories);
        } catch (Exception e) {
            log.error("Get categories failed", e);
            return ApiResponse.error("获取分类失败: " + e.getMessage());
        }
    }
}