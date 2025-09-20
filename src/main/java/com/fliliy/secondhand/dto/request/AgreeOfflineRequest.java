package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class AgreeOfflineRequest {
    
    @NotBlank(message = "回复消息不能为空")
    @Size(max = 500, message = "回复消息不能超过500个字符")
    private String message;
    
    @NotNull(message = "见面时间不能为空")
    private LocalDateTime meetingTime;
    
    @Valid
    @NotNull(message = "联系信息不能为空")
    private ContactInfo contactInfo;
    
    @Valid
    @NotNull(message = "见面地点不能为空")
    private MeetingLocation meetingLocation;
    
    @Size(max = 500, message = "备注不能超过500个字符")
    private String notes;
    
    @Data
    public static class ContactInfo {
        @NotBlank(message = "联系人姓名不能为空")
        @Size(max = 50, message = "联系人姓名不能超过50个字符")
        private String contactName;
        
        @NotBlank(message = "联系电话不能为空")
        @Size(max = 20, message = "联系电话不能超过20个字符")
        private String contactPhone;
    }
    
    @Data
    public static class MeetingLocation {
        @NotBlank(message = "地点名称不能为空")
        @Size(max = 100, message = "地点名称不能超过100个字符")
        private String locationName;
        
        @NotBlank(message = "详细地址不能为空")
        @Size(max = 255, message = "详细地址不能超过255个字符")
        private String detailAddress;
        
        private BigDecimal longitude;
        
        private BigDecimal latitude;
    }
}