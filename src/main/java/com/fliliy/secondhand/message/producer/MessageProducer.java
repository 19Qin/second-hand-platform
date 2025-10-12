package com.fliliy.secondhand.message.producer;

import com.fliliy.secondhand.constant.RabbitMQConstants;
import com.fliliy.secondhand.message.event.NotificationEvent;
import com.fliliy.secondhand.message.event.ProductDeletedEvent;
import com.fliliy.secondhand.message.event.ProductPublishedEvent;
import com.fliliy.secondhand.message.event.ProductUpdatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

/**
 * 消息生产者服务
 * 负责发送各种业务消息到RabbitMQ
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MessageProducer {

    private final RabbitTemplate rabbitTemplate;

    // ==================== 商品相关消息 ====================

    /**
     * 发送商品发布事件
     *
     * @param event 商品发布事件
     */
    public void sendProductPublished(ProductPublishedEvent event) {
        try {
            log.info("发送商品发布消息 - 商品ID: {}, 标题: {}", event.getProductId(), event.getTitle());
            rabbitTemplate.convertAndSend(
                    RabbitMQConstants.PRODUCT_EXCHANGE,
                    RabbitMQConstants.PRODUCT_PUBLISHED_ROUTING_KEY,
                    event
            );
            log.debug("商品发布消息发送成功 - 商品ID: {}", event.getProductId());
        } catch (Exception e) {
            log.error("发送商品发布消息失败 - 商品ID: {}, 错误: {}", event.getProductId(), e.getMessage(), e);
            throw new RuntimeException("发送商品发布消息失败", e);
        }
    }

    /**
     * 发送商品更新事件
     *
     * @param event 商品更新事件
     */
    public void sendProductUpdated(ProductUpdatedEvent event) {
        try {
            log.info("发送商品更新消息 - 商品ID: {}", event.getProductId());
            rabbitTemplate.convertAndSend(
                    RabbitMQConstants.PRODUCT_EXCHANGE,
                    RabbitMQConstants.PRODUCT_UPDATED_ROUTING_KEY,
                    event
            );
            log.debug("商品更新消息发送成功 - 商品ID: {}", event.getProductId());
        } catch (Exception e) {
            log.error("发送商品更新消息失败 - 商品ID: {}, 错误: {}", event.getProductId(), e.getMessage(), e);
            throw new RuntimeException("发送商品更新消息失败", e);
        }
    }

    /**
     * 发送商品删除事件
     *
     * @param event 商品删除事件
     */
    public void sendProductDeleted(ProductDeletedEvent event) {
        try {
            log.info("发送商品删除消息 - 商品ID: {}", event.getProductId());
            rabbitTemplate.convertAndSend(
                    RabbitMQConstants.PRODUCT_EXCHANGE,
                    RabbitMQConstants.PRODUCT_DELETED_ROUTING_KEY,
                    event
            );
            log.debug("商品删除消息发送成功 - 商品ID: {}", event.getProductId());
        } catch (Exception e) {
            log.error("发送商品删除消息失败 - 商品ID: {}, 错误: {}", event.getProductId(), e.getMessage(), e);
            throw new RuntimeException("发送商品删除消息失败", e);
        }
    }

    // ==================== 交易相关消息 ====================

    /**
     * 发送交易完成消息
     *
     * @param transactionId 交易ID
     */
    public void sendTransactionCompleted(Long transactionId) {
        try {
            log.info("发送交易完成消息 - 交易ID: {}", transactionId);
            rabbitTemplate.convertAndSend(
                    RabbitMQConstants.TRANSACTION_EXCHANGE,
                    RabbitMQConstants.TRANSACTION_COMPLETED_ROUTING_KEY,
                    transactionId
            );
            log.debug("交易完成消息发送成功 - 交易ID: {}", transactionId);
        } catch (Exception e) {
            log.error("发送交易完成消息失败 - 交易ID: {}, 错误: {}", transactionId, e.getMessage(), e);
            throw new RuntimeException("发送交易完成消息失败", e);
        }
    }

    /**
     * 发送交易取消消息
     *
     * @param transactionId 交易ID
     */
    public void sendTransactionCancelled(Long transactionId) {
        try {
            log.info("发送交易取消消息 - 交易ID: {}", transactionId);
            rabbitTemplate.convertAndSend(
                    RabbitMQConstants.TRANSACTION_EXCHANGE,
                    RabbitMQConstants.TRANSACTION_CANCELLED_ROUTING_KEY,
                    transactionId
            );
            log.debug("交易取消消息发送成功 - 交易ID: {}", transactionId);
        } catch (Exception e) {
            log.error("发送交易取消消息失败 - 交易ID: {}, 错误: {}", transactionId, e.getMessage(), e);
            throw new RuntimeException("发送交易取消消息失败", e);
        }
    }

    // ==================== 通知相关消息 ====================

    /**
     * 发送通知消息（广播到所有通知队列）
     *
     * @param event 通知事件
     */
    public void sendNotification(NotificationEvent event) {
        try {
            log.info("发送通知消息 - 类型: {}, 用户ID: {}, 标题: {}",
                    event.getType(), event.getUserId(), event.getTitle());
            rabbitTemplate.convertAndSend(
                    RabbitMQConstants.NOTIFICATION_EXCHANGE,
                    "", // Fanout交换机不需要路由键
                    event
            );
            log.debug("通知消息发送成功 - 用户ID: {}", event.getUserId());
        } catch (Exception e) {
            log.error("发送通知消息失败 - 用户ID: {}, 错误: {}", event.getUserId(), e.getMessage(), e);
            throw new RuntimeException("发送通知消息失败", e);
        }
    }

    /**
     * 发送商品发布通知
     *
     * @param userId    用户ID
     * @param productId 商品ID
     * @param title     商品标题
     */
    public void sendProductPublishedNotification(Long userId, Long productId, String title) {
        NotificationEvent event = new NotificationEvent(
                "PRODUCT_PUBLISHED",
                userId,
                "商品发布成功",
                String.format("您的商品「%s」已成功发布", title),
                "product",
                productId
        );
        sendNotification(event);
    }

    /**
     * 发送交易完成通知
     *
     * @param userId        用户ID
     * @param transactionId 交易ID
     * @param productTitle  商品标题
     */
    public void sendTransactionCompletedNotification(Long userId, Long transactionId, String productTitle) {
        NotificationEvent event = new NotificationEvent(
                "TRANSACTION_COMPLETED",
                userId,
                "交易已完成",
                String.format("商品「%s」的交易已完成", productTitle),
                "transaction",
                transactionId
        );
        sendNotification(event);
    }

    /**
     * 发送新消息通知
     *
     * @param userId       用户ID
     * @param chatRoomId   聊天室ID
     * @param senderName   发送者昵称
     * @param messagePreview 消息预览
     */
    public void sendNewMessageNotification(Long userId, Long chatRoomId, String senderName, String messagePreview) {
        NotificationEvent event = new NotificationEvent(
                "NEW_MESSAGE",
                userId,
                "新消息",
                String.format("%s: %s", senderName, messagePreview),
                "chat",
                chatRoomId
        );
        sendNotification(event);
    }
}
