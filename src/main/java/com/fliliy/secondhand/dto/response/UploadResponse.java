package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UploadResponse {
    
    private String url;           // 文件访问URL
    private String thumbnailUrl;  // 缩略图URL（图片才有）
    private String filename;      // 文件名
    private Long size;           // 文件大小（字节）
    private Integer duration;    // 语音时长（秒，语音文件才有）
    private Integer width;       // 图片宽度（图片才有）
    private Integer height;      // 图片高度（图片才有）
    private LocalDateTime uploadTime; // 上传时间
}