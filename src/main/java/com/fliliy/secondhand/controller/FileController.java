package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.response.UploadResponse;
import com.fliliy.secondhand.service.FileService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Path;
import java.nio.file.Paths;

@RestController
@RequestMapping("/files")
@RequiredArgsConstructor
@Slf4j
public class FileController {
    
    private final FileService fileService;
    
    @Value("${app.upload.path:/Users/yit/Desktop/second-hand-platform2/uploads/}")
    private String uploadBasePath;
    
    /**
     * 获取上传的文件
     */
    @GetMapping("/{category}/{filename:.+}")
    public ResponseEntity<Resource> getFile(
            @PathVariable String category,
            @PathVariable String filename) {
        try {
            Path filePath = Paths.get(uploadBasePath).resolve(category).resolve(filename);
            Resource resource = new UrlResource(filePath.toUri());
            
            if (!resource.exists() || !resource.isReadable()) {
                log.warn("File not found or not readable: {}", filePath);
                return ResponseEntity.notFound().build();
            }
            
            // 确定Content-Type
            String contentType = determineContentType(filename);
            
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .body(resource);
            
        } catch (MalformedURLException e) {
            log.error("File path error: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            log.error("Get file failed: category={}, filename={}", category, filename, e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    /**
     * 上传聊天文件（图片/语音）
     */
    @PostMapping("/chat/upload")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<UploadResponse> uploadChatFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") String type) {
        try {
            UploadResponse response = fileService.uploadChatFile(file, type);
            return ApiResponse.success("上传成功", response);
        } catch (Exception e) {
            log.error("Upload chat file failed", e);
            return ApiResponse.error("文件上传失败: " + e.getMessage());
        }
    }
    
    private String determineContentType(String filename) {
        String extension = getFileExtension(filename);
        if (extension == null) {
            return MediaType.APPLICATION_OCTET_STREAM_VALUE;
        }
        
        switch (extension.toLowerCase()) {
            case "jpg":
            case "jpeg":
                return MediaType.IMAGE_JPEG_VALUE;
            case "png":
                return MediaType.IMAGE_PNG_VALUE;
            case "gif":
                return MediaType.IMAGE_GIF_VALUE;
            case "webp":
                return "image/webp";
            case "mp3":
                return "audio/mpeg";
            case "aac":
                return "audio/aac";
            case "wav":
                return "audio/wav";
            default:
                return MediaType.APPLICATION_OCTET_STREAM_VALUE;
        }
    }
    
    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex == -1) {
            return null;
        }
        return filename.substring(lastDotIndex + 1);
    }
}