package com.fliliy.secondhand.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import javax.validation.constraints.Email;
import javax.validation.constraints.Size;
import java.time.LocalDate;

@Data
public class UpdateProfileRequest {
    
    @Size(min = 1, max = 50, message = "用户名长度必须在1-50个字符之间")
    private String username;
    
    private String avatar;
    
    private Integer gender; // 0未知, 1男, 2女
    
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthday;
    
    @Size(max = 200, message = "所在地区长度不能超过200个字符")
    private String location;
    
    @Size(max = 500, message = "个人简介长度不能超过500个字符")
    private String bio;
    
    @Email(message = "邮箱格式不正确")
    @Size(max = 100, message = "邮箱长度不能超过100个字符")
    private String email;
    
    // 用户偏好设置
    private Boolean pushNotification;
    private Boolean emailNotification;
    private Boolean showMobile;
    private Boolean showLocation;
}