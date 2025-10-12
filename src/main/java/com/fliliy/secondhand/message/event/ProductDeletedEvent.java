package com.fliliy.secondhand.message.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 商品删除事件
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductDeletedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 商品ID
     */
    private Long productId;

    /**
     * 删除时间
     */
    private LocalDateTime deletedAt;

    /**
     * 事件时间
     */
    private LocalDateTime eventTime;

    public ProductDeletedEvent(Long productId) {
        this.productId = productId;
        this.deletedAt = LocalDateTime.now();
        this.eventTime = LocalDateTime.now();
    }
}
