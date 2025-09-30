package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.util.Map;

@Data
public class SystemConfigResponse {
    
    private String version;
    private UploadConfig upload;
    private SmsConfig sms;
    private TransactionConfig transaction;
    private FeaturesConfig features;
    
    @Data
    public static class UploadConfig {
        private Integer maxImageCount;
        private String maxImageSize;
        private Integer maxVoiceDuration;
        private String[] supportedImageFormats;
        private String[] supportedVoiceFormats;
    }
    
    @Data
    public static class SmsConfig {
        private Integer codeLength;
        private Integer expireMinutes;
        private Integer dailyLimit;
    }
    
    @Data
    public static class TransactionConfig {
        private Integer codeLength;
        private Integer expireHours;
    }
    
    @Data
    public static class FeaturesConfig {
        private Boolean locationService;
        private Boolean aiEvaluation;
        private Boolean onlinePayment;
        private Boolean pushNotification;
    }
}