package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.service.ElasticsearchSyncService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * Elasticsearch管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/admin/elasticsearch")
@RequiredArgsConstructor
public class ElasticsearchAdminController {

    private final ElasticsearchSyncService elasticsearchSyncService;

    /**
     * 全量同步所有商品到ES
     */
    @PostMapping("/sync-all")
    public ApiResponse<Object> syncAllProducts() {
        log.info("接收全量同步请求");

        try {
            elasticsearchSyncService.syncAllProducts();
            return ApiResponse.success("全量同步任务已启动");
        } catch (Exception e) {
            log.error("全量同步失败", e);
            return ApiResponse.error("全量同步失败: " + e.getMessage());
        }
    }

    /**
     * 同步单个商品到ES
     */
    @PostMapping("/sync/{id}")
    public ApiResponse<Object> syncProduct(@PathVariable Long id) {
        log.info("接收单个商品同步请求 - ID: {}", id);

        try {
            elasticsearchSyncService.syncProduct(id);
            return ApiResponse.success("商品同步成功");
        } catch (Exception e) {
            log.error("商品同步失败 - ID: {}", id, e);
            return ApiResponse.error("商品同步失败: " + e.getMessage());
        }
    }

    /**
     * 从ES删除商品
     */
    @DeleteMapping("/delete/{id}")
    public ApiResponse<Object> deleteProduct(@PathVariable Long id) {
        log.info("接收删除商品请求 - ID: {}", id);

        try {
            elasticsearchSyncService.deleteProductFromEs(id);
            return ApiResponse.success("商品已从ES删除");
        } catch (Exception e) {
            log.error("删除商品失败 - ID: {}", id, e);
            return ApiResponse.error("删除商品失败: " + e.getMessage());
        }
    }

    /**
     * 重建ES索引(清空+全量同步)
     */
    @PostMapping("/rebuild")
    public ApiResponse<Object> rebuildIndex() {
        log.info("接收重建索引请求");

        try {
            elasticsearchSyncService.rebuildIndex();
            return ApiResponse.success("索引重建任务已启动");
        } catch (Exception e) {
            log.error("索引重建失败", e);
            return ApiResponse.error("索引重建失败: " + e.getMessage());
        }
    }

    /**
     * 清空ES索引
     */
    @PostMapping("/clear")
    public ApiResponse<Object> clearIndex() {
        log.info("接收清空索引请求");

        try {
            elasticsearchSyncService.clearEsIndex();
            return ApiResponse.success("ES索引已清空");
        } catch (Exception e) {
            log.error("清空索引失败", e);
            return ApiResponse.error("清空索引失败: " + e.getMessage());
        }
    }
}
