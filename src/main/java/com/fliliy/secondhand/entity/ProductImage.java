package com.fliliy.secondhand.entity;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "product_images")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductImage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "product_id", nullable = false)
    private Long productId;
    
    @Column(name = "image_url", nullable = false, length = 500)
    private String imageUrl;
    
    @Column(name = "thumbnail_url", length = 500)
    private String thumbnailUrl;
    
    @Column(name = "sort_order")
    private Integer sortOrder = 0;
    
    @Column(name = "image_size")
    private Integer imageSize;
    
    @Column(name = "image_width")
    private Integer imageWidth;
    
    @Column(name = "image_height")
    private Integer imageHeight;
    
    @Column(name = "upload_time", updatable = false)
    private LocalDateTime uploadTime;
    
    @PrePersist
    protected void onCreate() {
        uploadTime = LocalDateTime.now();
    }
    
    // 构造方法
    public ProductImage(Long productId, String imageUrl, Integer sortOrder) {
        this.productId = productId;
        this.imageUrl = imageUrl;
        this.sortOrder = sortOrder;
    }
    
    public ProductImage(Long productId, String imageUrl, String thumbnailUrl, Integer sortOrder) {
        this.productId = productId;
        this.imageUrl = imageUrl;
        this.thumbnailUrl = thumbnailUrl;
        this.sortOrder = sortOrder;
    }
}