package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class AddressResponse {
    
    private Long id;
    private String contactName;
    private String contactPhone;
    private String province;
    private String city;
    private String district;
    private String detailAddress;
    private String fullAddress;
    private BigDecimal longitude;
    private BigDecimal latitude;
    private Boolean isDefault;
    private Integer usageCount;
    private LocalDateTime createdAt;
    private LocalDateTime lastUsedAt;
    
    public String getFullAddress() {
        return province + city + district + detailAddress;
    }
}