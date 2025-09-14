package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.*;
import java.math.BigDecimal;

@Data
public class ProductQueryRequest {
    
    @Min(value = 1, message = "页码必须大于0")
    private Integer page = 1;
    
    @Min(value = 1, message = "每页数量必须大于0")
    @Max(value = 50, message = "每页数量不能超过50")
    private Integer size = 4;
    
    // 分类筛选
    @Min(value = 1, message = "分类ID必须大于0")
    private Integer categoryId;
    
    // 搜索关键词
    @Size(max = 100, message = "搜索关键词不能超过100字")
    private String keyword;
    
    // 筛选条件
    @Pattern(regexp = "all|popular|discount|brand|accessories", message = "筛选条件只能是all、popular、discount、brand或accessories")
    private String filter;
    
    // 排序方式
    @Pattern(regexp = "time_desc|time_asc|price_asc|price_desc|view_desc|favorite_desc", 
             message = "排序方式不正确")
    private String sort = "time_desc";
    
    // 价格区间
    @DecimalMin(value = "0.01", message = "最低价格必须大于0")
    private BigDecimal minPrice;
    
    @DecimalMin(value = "0.01", message = "最高价格必须大于0")
    private BigDecimal maxPrice;
    
    // 商品状况筛选
    @Pattern(regexp = "NEW|LIKE_NEW|GOOD|FAIR|POOR", message = "商品状况值不正确")
    private String condition;
    
    // 是否有保修
    private Boolean hasWarranty;
    
    // 地理位置搜索（附近商品）
    @DecimalMin(value = "-180.0", message = "经度范围：-180到180")
    @DecimalMax(value = "180.0", message = "经度范围：-180到180")
    private BigDecimal longitude;
    
    @DecimalMin(value = "-90.0", message = "纬度范围：-90到90")
    @DecimalMax(value = "90.0", message = "纬度范围：-90到90")
    private BigDecimal latitude;
    
    @Min(value = 100, message = "搜索半径至少100米")
    @Max(value = 50000, message = "搜索半径最大50公里")
    private Integer radius = 5000; // 默认5公里
    
    // 省市区筛选
    @Size(max = 50, message = "省份名称不能超过50字")
    private String province;
    
    @Size(max = 50, message = "城市名称不能超过50字")
    private String city;
    
    @Size(max = 50, message = "区县名称不能超过50字")
    private String district;
    
    // 卖家筛选（查询特定卖家的商品）
    @Min(value = 1, message = "卖家ID必须大于0")
    private Long sellerId;
    
    // 商品状态筛选（默认只查询在售商品）
    @Pattern(regexp = "ACTIVE|SOLD|INACTIVE|ALL", message = "商品状态值不正确")
    private String status = "ACTIVE";
    
    // 验证价格区间
    public boolean isPriceRangeValid() {
        if (minPrice != null && maxPrice != null) {
            return minPrice.compareTo(maxPrice) <= 0;
        }
        return true;
    }
    
    // 验证地理位置参数
    public boolean isLocationValid() {
        return (longitude == null && latitude == null) || 
               (longitude != null && latitude != null);
    }
}