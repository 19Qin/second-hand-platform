package com.fliliy.secondhand.message.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 通知事件
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotificationEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 通知类型
     */
    private String type;

    /**
     * 接收者用户ID
     */
    private Long userId;

    /**
     * 通知标题
     */
    private String title;

    /**
     * 通知内容
     */
    private String content;

    /**
     * 关联实体类型（product, transaction, chat等）
     */
    private String relatedType;

    /**
     * 关联实体ID
     */
    private Long relatedId;

    /**
     * 事件时间
     */
    private LocalDateTime eventTime;

    public NotificationEvent(String type, Long userId, String title, String content, String relatedType, Long relatedId) {
        this.type = type;
        this.userId = userId;
        this.title = title;
        this.content = content;
        this.relatedType = relatedType;
        this.relatedId = relatedId;
        this.eventTime = LocalDateTime.now();
    }
}
