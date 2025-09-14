package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class ProductDetailResponse {
    
    private String id;
    private String title;
    private String description;
    private BigDecimal price;
    private BigDecimal originalPrice;
    private String discount;
    private Integer categoryId;
    private String categoryName;
    private String categoryPath; // 如"电子产品 > 手机"
    
    private List<String> images;
    private String condition;
    private String conditionText;
    
    // 使用信息
    private UsageInfo usageInfo;
    
    // 保修信息
    private WarrantyInfo warranty;
    
    // 位置信息
    private LocationInfo location;
    
    // 卖家信息
    private SellerInfo seller;
    
    // 统计信息
    private StatsInfo stats;
    
    private LocalDateTime publishTime;
    private LocalDateTime updatedTime;
    private String status;
    private List<String> tags;
    
    // 相关推荐商品（可选）
    private List<RelatedProduct> relatedProducts;
    
    @Data
    public static class UsageInfo {
        private String type;
        private Integer value;
        private String unit;
        private String displayText; // 显示文本，如"使用6个月"
    }
    
    @Data
    public static class WarrantyInfo {
        private Boolean hasWarranty;
        private String warrantyType;
        private Integer remainingMonths;
        private String description;
        private String displayText; // 显示文本，如"苹果官方保修，剩余10个月"
    }
    
    @Data
    public static class LocationInfo {
        private String province;
        private String city;
        private String district;
        private String detailAddress;
        private String displayText; // 显示文本，如"北京市朝阳区三里屯"
        private String distance; // 距离信息，如"1.2km"
    }
    
    @Data
    public static class SellerInfo {
        private String id;
        private String username;
        private String avatar;
        private Boolean verified;
        private Integer registeredDays; // 注册天数
        private Integer totalProducts; // 总发布商品数
        private Integer soldCount; // 已售出数量
        private BigDecimal rating; // 平均评分
        private Integer reviewCount; // 评价总数
        private String responseRate; // 回复率，如"95%"
        private String avgResponseTime; // 平均回复时间，如"30分钟内"
    }
    
    @Data
    public static class StatsInfo {
        private Integer viewCount;
        private Integer favoriteCount;
        private Integer chatCount;
        private Boolean isOwn; // 是否是当前用户发布的
        private Boolean isFavorited; // 是否已收藏
    }
    
    @Data
    public static class RelatedProduct {
        private String id;
        private String title;
        private BigDecimal price;
        private String mainImage;
    }
}