package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.response.UploadResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@Slf4j
public class FileService {
    
    @Value("${app.upload.path:/Users/yit/Desktop/second-hand-platform2/uploads/}")
    private String uploadBasePath;
    
    @Value("${app.upload.max-size:10485760}")  // 10MB
    private long maxFileSize;
    
    @Value("${app.server.base-url:http://localhost:8080}")
    private String serverBaseUrl;
    
    // 支持的图片格式
    private static final List<String> SUPPORTED_IMAGE_TYPES = Arrays.asList(
            "image/jpeg", "image/jpg", "image/png", "image/webp"
    );
    
    // 缩略图尺寸
    private static final int THUMBNAIL_WIDTH = 300;
    private static final int THUMBNAIL_HEIGHT = 300;
    
    /**
     * 上传商品图片
     */
    public UploadResponse uploadProductImage(MultipartFile file) {
        try {
            // 1. 验证文件
            validateImageFile(file);
            
            // 2. 生成文件名和路径
            String originalFilename = file.getOriginalFilename();
            String fileExtension = getFileExtension(originalFilename);
            String filename = generateFilename(fileExtension);
            
            // 3. 创建上传目录
            String relativePath = "products/" + filename;
            Path uploadPath = Paths.get(uploadBasePath, relativePath);
            Files.createDirectories(uploadPath.getParent());
            
            // 4. 保存原图
            Files.copy(file.getInputStream(), uploadPath, StandardCopyOption.REPLACE_EXISTING);
            
            // 5. 生成缩略图
            String thumbnailPath = generateThumbnail(uploadPath, filename);
            
            // 6. 构建响应
            UploadResponse response = new UploadResponse();
            response.setUrl(serverBaseUrl + "/api/v1/files/" + relativePath);
            response.setThumbnailUrl(serverBaseUrl + "/api/v1/files/" + thumbnailPath);
            response.setFilename(filename);
            response.setSize(file.getSize());
            response.setUploadTime(LocalDateTime.now());
            
            log.info("Product image uploaded successfully: {}", relativePath);
            return response;
            
        } catch (IOException e) {
            log.error("Failed to upload product image: {}", e.getMessage());
            throw new RuntimeException("文件上传失败: " + e.getMessage());
        }
    }
    
    /**
     * 上传聊天文件（图片/语音）
     */
    public UploadResponse uploadChatFile(MultipartFile file, String type) {
        try {
            if ("image".equals(type)) {
                return uploadChatImage(file);
            } else if ("voice".equals(type)) {
                return uploadChatVoice(file);
            } else {
                throw new RuntimeException("不支持的文件类型: " + type);
            }
        } catch (Exception e) {
            log.error("Failed to upload chat file: {}", e.getMessage());
            throw new RuntimeException("文件上传失败: " + e.getMessage());
        }
    }
    
    /**
     * 批量删除文件
     */
    public void deleteFiles(List<String> fileUrls) {
        for (String fileUrl : fileUrls) {
            try {
                deleteFile(fileUrl);
            } catch (Exception e) {
                log.warn("Failed to delete file: {}, error: {}", fileUrl, e.getMessage());
            }
        }
    }
    
    /**
     * 删除单个文件
     */
    public void deleteFile(String fileUrl) {
        try {
            // 从URL中提取相对路径
            String relativePath = extractRelativePath(fileUrl);
            if (relativePath != null) {
                Path filePath = Paths.get(uploadBasePath, relativePath);
                Files.deleteIfExists(filePath);
                
                // 删除缩略图（如果存在）
                String thumbnailPath = relativePath.replace("/products/", "/products/thumb_");
                Path thumbPath = Paths.get(uploadBasePath, thumbnailPath);
                Files.deleteIfExists(thumbPath);
                
                log.info("File deleted: {}", relativePath);
            }
        } catch (IOException e) {
            log.error("Failed to delete file: {}", e.getMessage());
            throw new RuntimeException("文件删除失败: " + e.getMessage());
        }
    }
    
    // 私有方法
    
    private void validateImageFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new RuntimeException("文件不能为空");
        }
        
        if (file.getSize() > maxFileSize) {
            throw new RuntimeException("文件大小不能超过10MB");
        }
        
        String contentType = file.getContentType();
        if (!SUPPORTED_IMAGE_TYPES.contains(contentType)) {
            throw new RuntimeException("只支持 JPG, PNG, WebP 格式的图片");
        }
    }
    
    private void validateVoiceFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new RuntimeException("文件不能为空");
        }
        
        if (file.getSize() > maxFileSize) {
            throw new RuntimeException("文件大小不能超过10MB");
        }
        
        String contentType = file.getContentType();
        List<String> supportedVoiceTypes = Arrays.asList("audio/aac", "audio/mp3", "audio/wav", "audio/mpeg");
        if (!supportedVoiceTypes.contains(contentType)) {
            throw new RuntimeException("只支持 AAC, MP3, WAV 格式的音频文件");
        }
    }
    
    private String getFileExtension(String filename) {
        return StringUtils.getFilenameExtension(filename);
    }
    
    private String generateFilename(String extension) {
        return System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + "." + extension;
    }
    
    private String generateThumbnail(Path originalPath, String originalFilename) throws IOException {
        try {
            BufferedImage originalImage = ImageIO.read(originalPath.toFile());
            if (originalImage == null) {
                return null; // 无法读取图片，跳过缩略图生成
            }
            
            // 计算缩略图尺寸（保持比例）
            int originalWidth = originalImage.getWidth();
            int originalHeight = originalImage.getHeight();
            
            double scale = Math.min(
                    (double) THUMBNAIL_WIDTH / originalWidth,
                    (double) THUMBNAIL_HEIGHT / originalHeight
            );
            
            int thumbnailWidth = (int) (originalWidth * scale);
            int thumbnailHeight = (int) (originalHeight * scale);
            
            // 创建缩略图
            BufferedImage thumbnail = new BufferedImage(thumbnailWidth, thumbnailHeight, BufferedImage.TYPE_INT_RGB);
            Graphics2D g2d = thumbnail.createGraphics();
            g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g2d.drawImage(originalImage, 0, 0, thumbnailWidth, thumbnailHeight, null);
            g2d.dispose();
            
            // 保存缩略图
            String thumbnailFilename = "thumb_" + originalFilename;
            String thumbnailRelativePath = "products/" + thumbnailFilename;
            Path thumbnailPath = Paths.get(uploadBasePath, thumbnailRelativePath);
            
            String formatName = getFileExtension(originalFilename);
            if ("jpg".equalsIgnoreCase(formatName)) {
                formatName = "jpeg";
            }
            
            ImageIO.write(thumbnail, formatName, thumbnailPath.toFile());
            
            log.info("Thumbnail generated: {}", thumbnailRelativePath);
            return thumbnailRelativePath;
            
        } catch (Exception e) {
            log.warn("Failed to generate thumbnail for {}: {}", originalFilename, e.getMessage());
            return null;
        }
    }
    
    private UploadResponse uploadChatImage(MultipartFile file) throws IOException {
        validateImageFile(file);
        
        String originalFilename = file.getOriginalFilename();
        String fileExtension = getFileExtension(originalFilename);
        String filename = generateFilename(fileExtension);
        String relativePath = "chat/" + filename;
        
        Path uploadPath = Paths.get(uploadBasePath, relativePath);
        Files.createDirectories(uploadPath.getParent());
        Files.copy(file.getInputStream(), uploadPath, StandardCopyOption.REPLACE_EXISTING);
        
        // 生成缩略图
        String thumbnailPath = generateChatThumbnail(uploadPath, filename);
        
        UploadResponse response = new UploadResponse();
        response.setUrl(serverBaseUrl + "/api/v1/files/" + relativePath);
        if (thumbnailPath != null) {
            response.setThumbnailUrl(serverBaseUrl + "/api/v1/files/" + thumbnailPath);
        }
        response.setFilename(filename);
        response.setSize(file.getSize());
        response.setUploadTime(LocalDateTime.now());
        
        return response;
    }
    
    private UploadResponse uploadChatVoice(MultipartFile file) throws IOException {
        validateVoiceFile(file);
        
        String originalFilename = file.getOriginalFilename();
        String fileExtension = getFileExtension(originalFilename);
        String filename = generateFilename(fileExtension);
        String relativePath = "chat/" + filename;
        
        Path uploadPath = Paths.get(uploadBasePath, relativePath);
        Files.createDirectories(uploadPath.getParent());
        Files.copy(file.getInputStream(), uploadPath, StandardCopyOption.REPLACE_EXISTING);
        
        UploadResponse response = new UploadResponse();
        response.setUrl(serverBaseUrl + "/api/v1/files/" + relativePath);
        response.setFilename(filename);
        response.setSize(file.getSize());
        response.setUploadTime(LocalDateTime.now());
        // 语音时长需要通过其他方式获取，这里暂时不设置
        
        return response;
    }
    
    private String generateChatThumbnail(Path originalPath, String originalFilename) {
        // 聊天图片缩略图生成逻辑，可以使用较小的尺寸
        try {
            BufferedImage originalImage = ImageIO.read(originalPath.toFile());
            if (originalImage == null) {
                return null;
            }
            
            int thumbSize = 150; // 聊天缩略图使用150x150
            BufferedImage thumbnail = new BufferedImage(thumbSize, thumbSize, BufferedImage.TYPE_INT_RGB);
            Graphics2D g2d = thumbnail.createGraphics();
            g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g2d.drawImage(originalImage, 0, 0, thumbSize, thumbSize, null);
            g2d.dispose();
            
            String thumbnailFilename = "thumb_" + originalFilename;
            String thumbnailRelativePath = "chat/" + thumbnailFilename;
            Path thumbnailPath = Paths.get(uploadBasePath, thumbnailRelativePath);
            
            String formatName = getFileExtension(originalFilename);
            if ("jpg".equalsIgnoreCase(formatName)) {
                formatName = "jpeg";
            }
            
            ImageIO.write(thumbnail, formatName, thumbnailPath.toFile());
            return thumbnailRelativePath;
            
        } catch (Exception e) {
            log.warn("Failed to generate chat thumbnail: {}", e.getMessage());
            return null;
        }
    }
    
    private String extractRelativePath(String fileUrl) {
        if (fileUrl == null || !fileUrl.contains("/api/v1/files/")) {
            return null;
        }
        
        int index = fileUrl.indexOf("/api/v1/files/");
        return fileUrl.substring(index + "/api/v1/files/".length());
    }
}