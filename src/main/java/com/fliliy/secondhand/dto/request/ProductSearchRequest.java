package com.fliliy.secondhand.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 商品搜索请求
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductSearchRequest {

    /**
     * 搜索关键词(搜索标题和描述)
     */
    private String keyword;

    /**
     * 分类ID
     */
    private Integer categoryId;

    /**
     * 省份
     */
    private String province;

    /**
     * 城市
     */
    private String city;

    /**
     * 最低价格
     */
    private Double minPrice;

    /**
     * 最高价格
     */
    private Double maxPrice;

    /**
     * 商品状态(默认ACTIVE)
     */
    private String status;

    /**
     * 排序字段: publishedAt(发布时间), price(价格), viewCount(浏览量), favoriteCount(收藏量)
     */
    private String sortBy;

    /**
     * 排序方向: asc, desc
     */
    private String sortOrder;

    /**
     * 页码(从1开始)
     */
    private Integer page;

    /**
     * 每页数量
     */
    private Integer size;
}
