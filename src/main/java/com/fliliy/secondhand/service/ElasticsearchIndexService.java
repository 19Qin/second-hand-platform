package com.fliliy.secondhand.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fliliy.secondhand.document.ProductDocument;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.elasticsearch.action.delete.DeleteRequest;
import org.elasticsearch.action.delete.DeleteResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.client.RequestOptions;
import org.elasticsearch.client.RestHighLevelClient;
import org.elasticsearch.xcontent.XContentType;
import org.elasticsearch.rest.RestStatus;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * Elasticsearch 索引服务 - 使用 RestHighLevelClient 直接操作
 * 绕过 Spring Data Elasticsearch 的响应解析问题
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ElasticsearchIndexService {

    private final RestHighLevelClient restHighLevelClient;
    private final ObjectMapper objectMapper;

    private static final String INDEX_NAME = "products";

    /**
     * 索引商品文档
     */
    public boolean indexProduct(ProductDocument document) {
        try {
            // 转换为 Map
            Map<String, Object> documentMap = convertToMap(document);

            IndexRequest request = new IndexRequest(INDEX_NAME)
                .id(document.getId().toString())
                .source(objectMapper.writeValueAsString(documentMap), XContentType.JSON);

            IndexResponse response = restHighLevelClient.index(request, RequestOptions.DEFAULT);

            if (response.status() == RestStatus.OK || response.status() == RestStatus.CREATED) {
                log.info("商品索引成功 - ID: {}, 结果: {}", document.getId(), response.getResult());
                return true;
            } else {
                log.warn("商品索引失败 - ID: {}, 状态: {}", document.getId(), response.status());
                return false;
            }
        } catch (Exception e) {
            log.error("索引商品失败 - ID: {}, 错误: {}", document.getId(), e.getMessage(), e);
            return false;
        }
    }

    /**
     * 删除商品文档
     */
    public boolean deleteProduct(Long productId) {
        try {
            DeleteRequest request = new DeleteRequest(INDEX_NAME, productId.toString());
            DeleteResponse response = restHighLevelClient.delete(request, RequestOptions.DEFAULT);

            if (response.status() == RestStatus.OK || response.status() == RestStatus.NOT_FOUND) {
                log.info("商品删除成功 - ID: {}, 结果: {}", productId, response.getResult());
                return true;
            } else {
                log.warn("商品删除失败 - ID: {}, 状态: {}", productId, response.status());
                return false;
            }
        } catch (Exception e) {
            log.error("删除商品失败 - ID: {}, 错误: {}", productId, e.getMessage(), e);
            return false;
        }
    }

    /**
     * 转换 ProductDocument 为 Map
     */
    private Map<String, Object> convertToMap(ProductDocument document) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", document.getId());
        map.put("title", document.getTitle());
        map.put("description", document.getDescription());
        map.put("price", document.getPrice());
        map.put("categoryId", document.getCategoryId());
        map.put("categoryName", document.getCategoryName());
        map.put("province", document.getProvince());
        map.put("city", document.getCity());
        map.put("status", document.getStatus());
        map.put("sellerId", document.getSellerId());
        map.put("sellerNickname", document.getSellerNickname());
        map.put("sellerAvatar", document.getSellerAvatar());
        map.put("mainImage", document.getMainImage());
        map.put("viewCount", document.getViewCount());
        map.put("favoriteCount", document.getFavoriteCount());
        map.put("publishedAt", document.getPublishedAt());
        map.put("createdAt", document.getCreatedAt());
        map.put("updatedAt", document.getUpdatedAt());
        return map;
    }
}
