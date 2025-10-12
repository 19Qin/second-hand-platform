package com.fliliy.secondhand.message.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 商品发布事件
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductPublishedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 商品ID
     */
    private Long productId;

    /**
     * 商品标题
     */
    private String title;

    /**
     * 卖家ID
     */
    private Long sellerId;

    /**
     * 卖家昵称
     */
    private String sellerNickname;

    /**
     * 发布时间
     */
    private LocalDateTime publishedAt;

    /**
     * 事件时间
     */
    private LocalDateTime eventTime;

    public ProductPublishedEvent(Long productId, String title, Long sellerId, String sellerNickname, LocalDateTime publishedAt) {
        this.productId = productId;
        this.title = title;
        this.sellerId = sellerId;
        this.sellerNickname = sellerNickname;
        this.publishedAt = publishedAt;
        this.eventTime = LocalDateTime.now();
    }
}
