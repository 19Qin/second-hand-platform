package com.fliliy.secondhand.constant;

/**
 * RabbitMQ 常量定义
 * 定义交换机、队列、路由键等常量
 *
 * @author Claude Code
 * @date 2025-10-02
 */
public class RabbitMQConstants {

    // ==================== 商品相关 ====================

    /**
     * 商品交换机（Topic类型）
     */
    public static final String PRODUCT_EXCHANGE = "product.exchange";

    /**
     * 商品发布队列
     */
    public static final String PRODUCT_PUBLISHED_QUEUE = "product.published.queue";

    /**
     * 商品更新队列
     */
    public static final String PRODUCT_UPDATED_QUEUE = "product.updated.queue";

    /**
     * 商品删除队列
     */
    public static final String PRODUCT_DELETED_QUEUE = "product.deleted.queue";

    /**
     * 商品发布路由键
     */
    public static final String PRODUCT_PUBLISHED_ROUTING_KEY = "product.published";

    /**
     * 商品更新路由键
     */
    public static final String PRODUCT_UPDATED_ROUTING_KEY = "product.updated";

    /**
     * 商品删除路由键
     */
    public static final String PRODUCT_DELETED_ROUTING_KEY = "product.deleted";

    // ==================== 交易相关 ====================

    /**
     * 交易交换机（Topic类型）
     */
    public static final String TRANSACTION_EXCHANGE = "transaction.exchange";

    /**
     * 交易完成队列
     */
    public static final String TRANSACTION_COMPLETED_QUEUE = "transaction.completed.queue";

    /**
     * 交易取消队列
     */
    public static final String TRANSACTION_CANCELLED_QUEUE = "transaction.cancelled.queue";

    /**
     * 交易完成路由键
     */
    public static final String TRANSACTION_COMPLETED_ROUTING_KEY = "transaction.completed";

    /**
     * 交易取消路由键
     */
    public static final String TRANSACTION_CANCELLED_ROUTING_KEY = "transaction.cancelled";

    // ==================== 通知相关 ====================

    /**
     * 通知交换机（Fanout类型 - 广播）
     */
    public static final String NOTIFICATION_EXCHANGE = "notification.exchange";

    /**
     * 应用内通知队列
     */
    public static final String NOTIFICATION_APP_QUEUE = "notification.app.queue";

    /**
     * 短信通知队列
     */
    public static final String NOTIFICATION_SMS_QUEUE = "notification.sms.queue";

    /**
     * 邮件通知队列（预留）
     */
    public static final String NOTIFICATION_EMAIL_QUEUE = "notification.email.queue";

    // ==================== 死信队列 ====================

    /**
     * 死信交换机
     */
    public static final String DLX_EXCHANGE = "dlx.exchange";

    /**
     * 死信队列
     */
    public static final String DLX_QUEUE = "dlx.queue";

    /**
     * 死信路由键
     */
    public static final String DLX_ROUTING_KEY = "dlx.#";

    // ==================== 队列参数 ====================

    /**
     * 死信交换机参数key
     */
    public static final String X_DEAD_LETTER_EXCHANGE = "x-dead-letter-exchange";

    /**
     * 死信路由键参数key
     */
    public static final String X_DEAD_LETTER_ROUTING_KEY = "x-dead-letter-routing-key";

    /**
     * 消息TTL参数key（毫秒）
     */
    public static final String X_MESSAGE_TTL = "x-message-ttl";

    /**
     * 队列最大长度参数key
     */
    public static final String X_MAX_LENGTH = "x-max-length";

    private RabbitMQConstants() {
        // 私有构造函数，防止实例化
    }
}
