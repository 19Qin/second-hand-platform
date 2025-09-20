package com.fliliy.secondhand.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;
import java.util.Map;

public class ChatMessageResponse {
    
    private Long id;
    private Long senderId;
    private String senderName;
    private String type;
    private String content;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime sentAt;
    
    private Boolean isFromMe;
    private String status;
    
    // 图片消息相关字段
    private String thumbnail;
    private ImageSize imageSize;
    
    // 语音消息相关字段
    private Integer duration;
    private String waveform;
    
    // 系统消息相关字段
    private Map<String, Object> systemData;
    
    // 撤回相关字段
    private Boolean isRecalled;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime recalledAt;
    
    public ChatMessageResponse() {}
    
    public static class ImageSize {
        private Integer width;
        private Integer height;
        
        public ImageSize() {}
        
        public ImageSize(Integer width, Integer height) {
            this.width = width;
            this.height = height;
        }
        
        public Integer getWidth() {
            return width;
        }
        
        public void setWidth(Integer width) {
            this.width = width;
        }
        
        public Integer getHeight() {
            return height;
        }
        
        public void setHeight(Integer height) {
            this.height = height;
        }
    }
    
    // Getter和Setter方法
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getSenderId() {
        return senderId;
    }
    
    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }
    
    public String getSenderName() {
        return senderName;
    }
    
    public void setSenderName(String senderName) {
        this.senderName = senderName;
    }
    
    public String getType() {
        return type;
    }
    
    public void setType(String type) {
        this.type = type;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public LocalDateTime getSentAt() {
        return sentAt;
    }
    
    public void setSentAt(LocalDateTime sentAt) {
        this.sentAt = sentAt;
    }
    
    public Boolean getIsFromMe() {
        return isFromMe;
    }
    
    public void setIsFromMe(Boolean isFromMe) {
        this.isFromMe = isFromMe;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getThumbnail() {
        return thumbnail;
    }
    
    public void setThumbnail(String thumbnail) {
        this.thumbnail = thumbnail;
    }
    
    public ImageSize getImageSize() {
        return imageSize;
    }
    
    public void setImageSize(ImageSize imageSize) {
        this.imageSize = imageSize;
    }
    
    public Integer getDuration() {
        return duration;
    }
    
    public void setDuration(Integer duration) {
        this.duration = duration;
    }
    
    public String getWaveform() {
        return waveform;
    }
    
    public void setWaveform(String waveform) {
        this.waveform = waveform;
    }
    
    public Map<String, Object> getSystemData() {
        return systemData;
    }
    
    public void setSystemData(Map<String, Object> systemData) {
        this.systemData = systemData;
    }
    
    public Boolean getIsRecalled() {
        return isRecalled;
    }
    
    public void setIsRecalled(Boolean isRecalled) {
        this.isRecalled = isRecalled;
    }
    
    public LocalDateTime getRecalledAt() {
        return recalledAt;
    }
    
    public void setRecalledAt(LocalDateTime recalledAt) {
        this.recalledAt = recalledAt;
    }
    
    // 为了兼容ChatService中的使用，添加便利方法
    public void setImageWidth(Integer width) {
        if (this.imageSize == null) {
            this.imageSize = new ImageSize();
        }
        this.imageSize.setWidth(width);
    }
    
    public void setImageHeight(Integer height) {
        if (this.imageSize == null) {
            this.imageSize = new ImageSize();
        }
        this.imageSize.setHeight(height);
    }
    
    public Integer getImageWidth() {
        return this.imageSize != null ? this.imageSize.getWidth() : null;
    }
    
    public Integer getImageHeight() {
        return this.imageSize != null ? this.imageSize.getHeight() : null;
    }
}