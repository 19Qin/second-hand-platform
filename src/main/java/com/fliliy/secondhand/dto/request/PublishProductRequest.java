package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

@Data
public class PublishProductRequest {
    
    @NotBlank(message = "商品标题不能为空")
    @Size(max = 200, message = "商品标题不能超过200字")
    private String title;
    
    @Size(max = 5000, message = "商品描述不能超过5000字")
    private String description;
    
    @NotNull(message = "商品价格不能为空")
    @DecimalMin(value = "0.01", message = "商品价格必须大于0")
    @DecimalMax(value = "999999.99", message = "商品价格不能超过999999.99")
    private BigDecimal price;
    
    @DecimalMin(value = "0.01", message = "原价必须大于0")
    @DecimalMax(value = "999999.99", message = "原价不能超过999999.99")
    private BigDecimal originalPrice;
    
    @NotNull(message = "商品分类不能为空")
    @Min(value = 1, message = "商品分类ID必须大于0")
    private Integer categoryId;
    
    @NotEmpty(message = "商品图片不能为空")
    @Size(max = 20, message = "商品图片最多20张")
    private List<String> images;
    
    @NotBlank(message = "商品状况不能为空")
    @Pattern(regexp = "NEW|LIKE_NEW|GOOD|FAIR|POOR", message = "商品状况值不正确")
    private String condition;
    
    // 使用信息
    private UsageInfo usageInfo;
    
    // 保修信息
    private WarrantyInfo warranty;
    
    // 位置信息
    @NotNull(message = "位置信息不能为空")
    private LocationInfo location;
    
    // 标签
    @Size(max = 10, message = "商品标签最多10个")
    private List<String> tags;
    
    @Data
    public static class UsageInfo {
        @Pattern(regexp = "TIME|COUNT", message = "使用情况类型只能是TIME或COUNT")
        private String type;
        
        @Min(value = 0, message = "使用数值不能小于0")
        private Integer value;
        
        @Pattern(regexp = "MONTH|YEAR", message = "使用时间单位只能是MONTH或YEAR")
        private String unit;
    }
    
    @Data
    public static class WarrantyInfo {
        private Boolean hasWarranty = false;
        
        @Pattern(regexp = "OFFICIAL|STORE|NONE", message = "保修类型只能是OFFICIAL、STORE或NONE")
        private String warrantyType = "NONE";
        
        @Min(value = 0, message = "保修月数不能小于0")
        @Max(value = 120, message = "保修月数不能超过120个月")
        private Integer remainingMonths = 0;
        
        @Size(max = 200, message = "保修说明不能超过200字")
        private String description;
    }
    
    @Data
    public static class LocationInfo {
        @NotBlank(message = "省份不能为空")
        @Size(max = 50, message = "省份名称不能超过50字")
        private String province;
        
        @NotBlank(message = "城市不能为空")
        @Size(max = 50, message = "城市名称不能超过50字")
        private String city;
        
        @NotBlank(message = "区县不能为空")
        @Size(max = 50, message = "区县名称不能超过50字")
        private String district;
        
        @Size(max = 200, message = "详细地址不能超过200字")
        private String detailAddress;
        
        @DecimalMin(value = "-180.0", message = "经度范围：-180到180")
        @DecimalMax(value = "180.0", message = "经度范围：-180到180")
        private BigDecimal longitude;
        
        @DecimalMin(value = "-90.0", message = "纬度范围：-90到90")
        @DecimalMax(value = "90.0", message = "纬度范围：-90到90")
        private BigDecimal latitude;
    }
}