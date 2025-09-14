package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class ProductSummaryResponse {
    
    private String id;
    private String title;
    private BigDecimal price;
    private BigDecimal originalPrice;
    private String discount; // 折扣信息，如"85折"
    private String mainImage;
    private String condition;
    private String conditionText;
    private String location; // 位置信息，如"北京市朝阳区"
    private String distance; // 距离信息，如"1.2km"
    private LocalDateTime publishTime;
    private Boolean hasWarranty;
    private String warrantyText; // 保修信息，如"保修10个月"
    
    // 卖家信息
    private SellerInfo seller;
    
    // 统计信息
    private StatsInfo stats;
    
    // 标签
    private List<String> tags;
    
    @Data
    public static class SellerInfo {
        private String id;
        private String username;
        private String avatar;
        private Boolean verified;
        private BigDecimal rating;
        private Integer ratingCount;
    }
    
    @Data
    public static class StatsInfo {
        private Integer viewCount;
        private Integer favoriteCount;
        private Integer chatCount;
        private Boolean isOwn; // 是否是当前用户发布的
        private Boolean isFavorited; // 是否已收藏
    }
}