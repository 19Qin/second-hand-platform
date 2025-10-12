package com.fliliy.secondhand.message.consumer;

import com.fliliy.secondhand.constant.RabbitMQConstants;
import com.fliliy.secondhand.entity.UserNotification;
import com.fliliy.secondhand.message.event.NotificationEvent;
import com.fliliy.secondhand.repository.UserNotificationRepository;
import com.rabbitmq.client.Channel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.LocalDateTime;

/**
 * 通知消费者
 * 监听通知消息，保存到数据库
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationConsumer {

    private final UserNotificationRepository userNotificationRepository;

    /**
     * 消费应用内通知消息
     * 将通知保存到数据库
     *
     * @param event   通知事件
     * @param message 消息对象
     * @param channel 通道
     */
    @RabbitListener(queues = RabbitMQConstants.NOTIFICATION_APP_QUEUE)
    public void handleAppNotification(NotificationEvent event, Message message, Channel channel) {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            log.info("收到应用内通知消息 - 类型: {}, 用户ID: {}, 标题: {}",
                    event.getType(), event.getUserId(), event.getTitle());

            // 创建通知实体
            UserNotification notification = new UserNotification();
            notification.setUserId(event.getUserId());
            // 根据事件类型映射到枚举
            notification.setType(mapNotificationType(event.getType()));
            notification.setTitle(event.getTitle());
            notification.setContent(event.getContent());
            // 根据相关类型映射到枚举
            notification.setRelatedType(mapRelatedType(event.getRelatedType()));
            notification.setRelatedId(event.getRelatedId());
            notification.setIsRead(false);
            notification.setCreatedAt(LocalDateTime.now());

            // 保存到数据库
            userNotificationRepository.save(notification);

            log.info("应用内通知消息处理成功 - 用户ID: {}, 通知ID: {}",
                    event.getUserId(), notification.getId());

            // 手动ACK确认
            channel.basicAck(deliveryTag, false);

        } catch (Exception e) {
            log.error("处理应用内通知消息失败 - 用户ID: {}, 错误: {}",
                    event.getUserId(), e.getMessage(), e);

            try {
                boolean requeue = shouldRequeue(message);
                channel.basicNack(deliveryTag, false, requeue);

                if (!requeue) {
                    log.warn("应用内通知消息处理失败次数过多，已发送到死信队列 - 用户ID: {}", event.getUserId());
                }
            } catch (IOException ioException) {
                log.error("消息NACK失败 - 用户ID: {}", event.getUserId(), ioException);
            }
        }
    }

    /**
     * 消费短信通知消息
     * 发送短信（当前仅记录日志，实际项目中需要对接短信服务）
     *
     * @param event   通知事件
     * @param message 消息对象
     * @param channel 通道
     */
    @RabbitListener(queues = RabbitMQConstants.NOTIFICATION_SMS_QUEUE)
    public void handleSmsNotification(NotificationEvent event, Message message, Channel channel) {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            log.info("收到短信通知消息 - 类型: {}, 用户ID: {}, 内容: {}",
                    event.getType(), event.getUserId(), event.getContent());

            // TODO: 对接短信服务发送短信
            // 当前仅记录日志
            log.info("模拟发送短信通知 - 用户ID: {}, 内容: {}", event.getUserId(), event.getContent());

            // 手动ACK确认
            channel.basicAck(deliveryTag, false);

            log.info("短信通知消息处理成功 - 用户ID: {}", event.getUserId());

        } catch (Exception e) {
            log.error("处理短信通知消息失败 - 用户ID: {}, 错误: {}",
                    event.getUserId(), e.getMessage(), e);

            try {
                boolean requeue = shouldRequeue(message);
                channel.basicNack(deliveryTag, false, requeue);

                if (!requeue) {
                    log.warn("短信通知消息处理失败次数过多，已发送到死信队列 - 用户ID: {}", event.getUserId());
                }
            } catch (IOException ioException) {
                log.error("消息NACK失败 - 用户ID: {}", event.getUserId(), ioException);
            }
        }
    }

    /**
     * 判断消息是否应该重新入队
     *
     * @param message 消息对象
     * @return true-重新入队，false-不重新入队（发送到死信队列）
     */
    private boolean shouldRequeue(Message message) {
        Integer retryCount = (Integer) message.getMessageProperties().getHeaders().get("x-retry-count");
        if (retryCount == null) {
            retryCount = 0;
        }

        final int MAX_RETRY_COUNT = 3;
        if (retryCount >= MAX_RETRY_COUNT) {
            log.warn("消息重试次数已达上限 ({}/{}), 不再重新入队", retryCount, MAX_RETRY_COUNT);
            return false;
        }

        message.getMessageProperties().getHeaders().put("x-retry-count", retryCount + 1);
        log.info("消息将重新入队 - 当前重试次数: {}/{}", retryCount + 1, MAX_RETRY_COUNT);
        return true;
    }

    /**
     * 映射通知类型字符串到枚举
     */
    private UserNotification.NotificationType mapNotificationType(String type) {
        if (type == null) {
            return UserNotification.NotificationType.SYSTEM;
        }
        switch (type.toUpperCase()) {
            case "PRODUCT_PUBLISHED":
            case "PRODUCT":
                return UserNotification.NotificationType.PRODUCT;
            case "TRANSACTION_COMPLETED":
            case "TRANSACTION_CANCELLED":
            case "TRANSACTION":
                return UserNotification.NotificationType.TRANSACTION;
            case "NEW_MESSAGE":
            case "CHAT":
                return UserNotification.NotificationType.CHAT;
            case "PROMOTION":
                return UserNotification.NotificationType.PROMOTION;
            default:
                return UserNotification.NotificationType.SYSTEM;
        }
    }

    /**
     * 映射关联类型字符串到枚举
     */
    private UserNotification.RelatedType mapRelatedType(String relatedType) {
        if (relatedType == null) {
            return null;
        }
        switch (relatedType.toLowerCase()) {
            case "product":
                return UserNotification.RelatedType.PRODUCT;
            case "transaction":
                return UserNotification.RelatedType.TRANSACTION;
            case "chat":
                return UserNotification.RelatedType.CHAT;
            case "user":
                return UserNotification.RelatedType.USER;
            default:
                return null;
        }
    }
}
