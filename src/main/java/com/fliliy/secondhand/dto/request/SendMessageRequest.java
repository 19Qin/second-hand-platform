package com.fliliy.secondhand.dto.request;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;

public class SendMessageRequest {
    
    @NotNull(message = "消息类型不能为空")
    private String type; // TEXT, IMAGE, VOICE
    
    @NotEmpty(message = "消息内容不能为空")
    private String content;
    
    // 图片消息相关字段
    private String thumbnail;
    private Integer width;
    private Integer height;
    private Integer fileSize;
    
    // 语音消息相关字段
    private Integer duration; // 语音时长（秒）
    
    public SendMessageRequest() {}
    
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
    
    public String getThumbnail() {
        return thumbnail;
    }
    
    public void setThumbnail(String thumbnail) {
        this.thumbnail = thumbnail;
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
    
    public Integer getFileSize() {
        return fileSize;
    }
    
    public void setFileSize(Integer fileSize) {
        this.fileSize = fileSize;
    }
    
    public Integer getDuration() {
        return duration;
    }
    
    public void setDuration(Integer duration) {
        this.duration = duration;
    }
}