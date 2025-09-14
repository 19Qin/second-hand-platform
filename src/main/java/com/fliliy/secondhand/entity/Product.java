package com.fliliy.secondhand.entity;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Product {
    
    @Id
    private Long id;
    
    @Column(name = "seller_id", nullable = false)
    private Long sellerId;
    
    @Column(name = "category_id", nullable = false)
    private Integer categoryId;
    
    // 基本信息
    @Column(nullable = false, length = 200)
    private String title;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
    
    @Column(name = "original_price", precision = 10, scale = 2)
    private BigDecimal originalPrice;
    
    // 商品状况
    @Enumerated(EnumType.STRING)
    @Column(name = "product_condition", nullable = false)
    private ConditionType productCondition;
    
    // 使用情况
    @Enumerated(EnumType.STRING)
    @Column(name = "usage_type")
    private UsageType usageType;
    
    @Column(name = "usage_value")
    private Integer usageValue;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "usage_unit")
    private UsageUnit usageUnit;
    
    // 保修信息
    @Column(name = "has_warranty")
    private Boolean hasWarranty = false;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "warranty_type")
    private WarrantyType warrantyType = WarrantyType.NONE;
    
    @Column(name = "warranty_months")
    private Integer warrantyMonths = 0;
    
    @Column(name = "warranty_description", length = 200)
    private String warrantyDescription;
    
    // 位置信息
    @Column(length = 50)
    private String province;
    
    @Column(length = 50)
    private String city;
    
    @Column(length = 50)
    private String district;
    
    @Column(name = "detail_address", length = 200)
    private String detailAddress;
    
    @Column(precision = 11, scale = 8)
    private BigDecimal longitude;
    
    @Column(precision = 10, scale = 8)
    private BigDecimal latitude;
    
    // 商品状态
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductStatus status = ProductStatus.ACTIVE;
    
    // 统计数据
    @Column(name = "view_count")
    private Integer viewCount = 0;
    
    @Column(name = "favorite_count")
    private Integer favoriteCount = 0;
    
    @Column(name = "chat_count")
    private Integer chatCount = 0;
    
    @Column(name = "inquiry_count")
    private Integer inquiryCount = 0;
    
    // 推广相关
    @Column(name = "is_promoted")
    private Boolean isPromoted = false;
    
    @Column(name = "promoted_at")
    private LocalDateTime promotedAt;
    
    @Column(name = "promoted_expires_at")
    private LocalDateTime promotedExpiresAt;
    
    // 时间字段
    @Column(name = "published_at")
    private LocalDateTime publishedAt;
    
    @Column(name = "sold_at")
    private LocalDateTime soldAt;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;
    
    // 关联实体（用于查询时获取相关数据）
    @Transient
    private Category category;
    
    @Transient
    private User seller;
    
    @Transient
    private List<ProductImage> images;
    
    @Transient
    private List<ProductTag> tags;
    
    @Transient
    private String mainImage;  // 主图URL
    
    @Transient
    private Boolean isFavorited = false;  // 当前用户是否收藏
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (publishedAt == null) {
            publishedAt = LocalDateTime.now();
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // 枚举定义
    public enum ConditionType {
        NEW("全新"),
        LIKE_NEW("几乎全新"), 
        GOOD("轻微使用痕迹"),
        FAIR("明显使用痕迹"),
        POOR("需要维修");
        
        private final String description;
        
        ConditionType(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
    
    public enum UsageType {
        TIME("时间"),
        COUNT("次数");
        
        private final String description;
        
        UsageType(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
    
    public enum UsageUnit {
        MONTH("月"),
        YEAR("年");
        
        private final String description;
        
        UsageUnit(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
    
    public enum WarrantyType {
        OFFICIAL("官方保修"),
        STORE("店铺保修"),
        NONE("无保修");
        
        private final String description;
        
        WarrantyType(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
    
    public enum ProductStatus {
        DRAFT("草稿"),
        ACTIVE("在售中"),
        SOLD("已售出"),
        INACTIVE("已下架");
        
        private final String description;
        
        ProductStatus(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
}