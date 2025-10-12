package com.fliliy.secondhand.dto.request;

import com.fliliy.secondhand.validation.ValidPhoneNumber;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.math.BigDecimal;

@Data
public class AddAddressRequest {

    @NotBlank(message = "联系人姓名不能为空")
    @Size(min = 1, max = 50, message = "联系人姓名长度应在1-50字符之间")
    private String contactName;

    @NotBlank(message = "联系电话不能为空")
    @ValidPhoneNumber(message = "手机号格式不正确")
    private String contactPhone;
    
    @NotBlank(message = "省份不能为空")
    @Size(max = 50, message = "省份名称不能超过50字符")
    private String province;

    @NotBlank(message = "城市不能为空")
    @Size(max = 50, message = "城市名称不能超过50字符")
    private String city;

    @NotBlank(message = "区县不能为空")
    @Size(max = 50, message = "区县名称不能超过50字符")
    private String district;

    @NotBlank(message = "详细地址不能为空")
    @Size(min = 5, max = 200, message = "详细地址长度应在5-200字符之间")
    private String detailAddress;
    
    private BigDecimal longitude;
    
    private BigDecimal latitude;
    
    private Boolean isDefault = false;
}