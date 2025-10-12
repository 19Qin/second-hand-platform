package com.fliliy.secondhand.service;

import com.fliliy.secondhand.document.ProductDocument;
import com.fliliy.secondhand.dto.ProductDTO;
import com.fliliy.secondhand.dto.request.ProductSearchRequest;
import com.fliliy.secondhand.dto.response.ProductSearchResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.elasticsearch.index.query.BoolQueryBuilder;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.search.fetch.subphase.highlight.HighlightBuilder;
import org.elasticsearch.search.sort.SortBuilders;
import org.elasticsearch.search.sort.SortOrder;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.ElasticsearchRestTemplate;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.query.NativeSearchQuery;
import org.springframework.data.elasticsearch.core.query.NativeSearchQueryBuilder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商品搜索服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ProductSearchService {

    private final ElasticsearchRestTemplate elasticsearchRestTemplate;

    /**
     * 搜索商品
     */
    public ProductSearchResponse searchProducts(ProductSearchRequest request) {
        long startTime = System.currentTimeMillis();

        log.info("搜索商品 - 请求参数: {}", request);

        // 构建查询条件
        BoolQueryBuilder boolQuery = QueryBuilders.boolQuery();

        // 关键词搜索 (title + description)
        if (request.getKeyword() != null && !request.getKeyword().trim().isEmpty()) {
            String keyword = request.getKeyword().trim();
            boolQuery.must(QueryBuilders.multiMatchQuery(keyword, "title", "description")
                .analyzer("ik_smart"));
        }

        // 分类筛选
        if (request.getCategoryId() != null) {
            boolQuery.filter(QueryBuilders.termQuery("categoryId", request.getCategoryId()));
        }

        // 价格范围筛选
        if (request.getMinPrice() != null || request.getMaxPrice() != null) {
            org.elasticsearch.index.query.RangeQueryBuilder rangeQuery = QueryBuilders.rangeQuery("price");
            if (request.getMinPrice() != null) {
                rangeQuery.gte(request.getMinPrice());
            }
            if (request.getMaxPrice() != null) {
                rangeQuery.lte(request.getMaxPrice());
            }
            boolQuery.filter(rangeQuery);
        }

        // 城市筛选
        if (request.getCity() != null && !request.getCity().trim().isEmpty()) {
            boolQuery.filter(QueryBuilders.termQuery("city", request.getCity().trim()));
        }

        // 省份筛选
        if (request.getProvince() != null && !request.getProvince().trim().isEmpty()) {
            boolQuery.filter(QueryBuilders.termQuery("province", request.getProvince().trim()));
        }

        // 状态筛选 (默认只搜索ACTIVE状态)
        String status = request.getStatus() != null ? request.getStatus() : "ACTIVE";
        boolQuery.filter(QueryBuilders.termQuery("status", status));

        // 构建分页
        int page = request.getPage() != null && request.getPage() > 0 ? request.getPage() - 1 : 0;
        int size = request.getSize() != null && request.getSize() > 0 ? request.getSize() : 20;
        Pageable pageable = PageRequest.of(page, size);

        // 构建高亮
        HighlightBuilder highlightBuilder = new HighlightBuilder()
            .field("title")
            .field("description")
            .preTags("<em class=\"highlight\">")
            .postTags("</em>");

        // 构建排序
        NativeSearchQueryBuilder queryBuilder = new NativeSearchQueryBuilder()
            .withQuery(boolQuery)
            .withPageable(pageable)
            .withHighlightBuilder(highlightBuilder);

        // 排序逻辑
        // 支持两种格式:
        // 1. sortBy=price_asc 或 sortBy=price_desc (组合格式)
        // 2. sortBy=price&sortOrder=asc (分离格式)
        String sortBy = request.getSortBy() != null ? request.getSortBy() : "publishedAt";
        String sortOrder = request.getSortOrder() != null ? request.getSortOrder() : "desc";

        log.info("原始排序参数 - sortBy: {}, sortOrder: {}", sortBy, sortOrder);

        // 如果sortBy包含下划线,解析为字段和方向
        if (sortBy.contains("_")) {
            String[] parts = sortBy.split("_", 2);
            sortBy = parts[0];
            sortOrder = parts.length > 1 ? parts[1] : "desc";
            log.info("解析后排序参数 - sortBy: {}, sortOrder: {}", sortBy, sortOrder);
        }

        switch (sortBy) {
            case "price":
                queryBuilder.withSort(SortBuilders.fieldSort("price")
                    .order("asc".equalsIgnoreCase(sortOrder) ? SortOrder.ASC : SortOrder.DESC));
                break;
            case "viewCount":
            case "view":
                queryBuilder.withSort(SortBuilders.fieldSort("viewCount")
                    .order("asc".equalsIgnoreCase(sortOrder) ? SortOrder.ASC : SortOrder.DESC));
                break;
            case "favoriteCount":
            case "favorite":
                queryBuilder.withSort(SortBuilders.fieldSort("favoriteCount")
                    .order("asc".equalsIgnoreCase(sortOrder) ? SortOrder.ASC : SortOrder.DESC));
                break;
            case "publishedAt":
            case "time":
            default:
                queryBuilder.withSort(SortBuilders.fieldSort("publishedAt")
                    .order("asc".equalsIgnoreCase(sortOrder) ? SortOrder.ASC : SortOrder.DESC));
        }

        NativeSearchQuery searchQuery = queryBuilder.build();

        // 执行搜索
        SearchHits<ProductDocument> searchHits = elasticsearchRestTemplate.search(
            searchQuery,
            ProductDocument.class
        );

        // 转换结果
        List<ProductDTO> products = searchHits.getSearchHits().stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());

        long endTime = System.currentTimeMillis();
        long took = endTime - startTime;

        // 构建响应
        ProductSearchResponse response = ProductSearchResponse.builder()
            .products(products)
            .keyword(request.getKeyword())
            .total(searchHits.getTotalHits())
            .hasMore((page + 1) * size < searchHits.getTotalHits())
            .took(took)
            .build();

        // 设置分页信息
        com.fliliy.secondhand.dto.response.PagedResponse.PaginationInfo pagination =
            com.fliliy.secondhand.dto.response.PagedResponse.PaginationInfo.builder()
            .page(page + 1)
            .size(size)
            .total(searchHits.getTotalHits())
            .totalPages((int) Math.ceil((double) searchHits.getTotalHits() / size))
            .hasNext((page + 1) * size < searchHits.getTotalHits())
            .hasPrevious(page > 0)
            .isFirst(page == 0)
            .isLast((page + 1) * size >= searchHits.getTotalHits())
            .build();

        response.setPagination(pagination);

        log.info("搜索完成 - 总数: {}, 耗时: {} ms", searchHits.getTotalHits(), took);
        return response;
    }

    /**
     * 搜索建议
     */
    public List<String> searchSuggest(String prefix, int size) {
        if (prefix == null || prefix.trim().isEmpty()) {
            return new ArrayList<>();
        }

        log.info("搜索建议 - 前缀: {}, 大小: {}", prefix, size);

        // 使用前缀查询标题字段
        BoolQueryBuilder boolQuery = QueryBuilders.boolQuery()
            .must(QueryBuilders.matchPhrasePrefixQuery("title", prefix.trim()))
            .filter(QueryBuilders.termQuery("status", "ACTIVE"));

        NativeSearchQuery searchQuery = new NativeSearchQueryBuilder()
            .withQuery(boolQuery)
            .withPageable(PageRequest.of(0, size))
            .withFields("title")
            .build();

        SearchHits<ProductDocument> searchHits = elasticsearchRestTemplate.search(
            searchQuery,
            ProductDocument.class
        );

        // 提取标题作为建议
        List<String> suggestions = searchHits.getSearchHits().stream()
            .map(hit -> hit.getContent().getTitle())
            .distinct()
            .limit(size)
            .collect(Collectors.toList());

        log.info("搜索建议完成 - 返回 {} 条", suggestions.size());
        return suggestions;
    }

    /**
     * 转换SearchHit到ProductDTO(包含高亮处理)
     */
    private ProductDTO convertToDTO(SearchHit<ProductDocument> searchHit) {
        ProductDocument document = searchHit.getContent();
        Map<String, List<String>> highlightFields = searchHit.getHighlightFields();

        ProductDTO dto = new ProductDTO();
        dto.setId(document.getId());

        // 处理高亮标题
        if (highlightFields.containsKey("title") && !highlightFields.get("title").isEmpty()) {
            dto.setTitle(highlightFields.get("title").get(0));
        } else {
            dto.setTitle(document.getTitle());
        }

        // 处理高亮描述
        if (highlightFields.containsKey("description") && !highlightFields.get("description").isEmpty()) {
            dto.setDescription(highlightFields.get("description").get(0));
        } else {
            dto.setDescription(document.getDescription());
        }

        dto.setPrice(document.getPrice());
        dto.setProvince(document.getProvince());
        dto.setCity(document.getCity());
        dto.setStatus(document.getStatus());
        dto.setMainImage(document.getMainImage());
        dto.setViewCount(document.getViewCount());
        dto.setFavoriteCount(document.getFavoriteCount());
        dto.setSellerNickname(document.getSellerNickname());
        dto.setSellerAvatar(document.getSellerAvatar());
        dto.setCategoryName(document.getCategoryName());
        dto.setPublishedAt(document.getPublishedAt());

        return dto;
    }
}
