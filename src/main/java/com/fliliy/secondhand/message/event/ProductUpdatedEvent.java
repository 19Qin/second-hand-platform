package com.fliliy.secondhand.message.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 商品更新事件
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductUpdatedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 商品ID
     */
    private Long productId;

    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;

    /**
     * 事件时间
     */
    private LocalDateTime eventTime;

    public ProductUpdatedEvent(Long productId) {
        this.productId = productId;
        this.updatedAt = LocalDateTime.now();
        this.eventTime = LocalDateTime.now();
    }
}
