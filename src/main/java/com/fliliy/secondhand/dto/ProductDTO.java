package com.fliliy.secondhand.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 商品DTO - 用于ES搜索返回
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductDTO {

    /**
     * 商品ID
     */
    private Long id;

    /**
     * 商品标题(可能包含高亮标签)
     */
    private String title;

    /**
     * 商品描述(可能包含高亮标签)
     */
    private String description;

    /**
     * 价格
     */
    private BigDecimal price;

    /**
     * 省份
     */
    private String province;

    /**
     * 城市
     */
    private String city;

    /**
     * 商品状态
     */
    private String status;

    /**
     * 主图URL
     */
    private String mainImage;

    /**
     * 浏览次数
     */
    private Integer viewCount;

    /**
     * 收藏次数
     */
    private Integer favoriteCount;

    /**
     * 卖家昵称
     */
    private String sellerNickname;

    /**
     * 卖家头像
     */
    private String sellerAvatar;

    /**
     * 分类名称
     */
    private String categoryName;

    /**
     * 发布时间
     */
    private LocalDateTime publishedAt;
}
