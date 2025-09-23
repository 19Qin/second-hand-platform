-- ===============================================
-- 聊天系统性能优化索引
-- 提升查询性能和用户体验
-- ===============================================

-- 1. 聊天室表索引优化
-- 用户对唯一性约束（防止重复聊天室）
CREATE UNIQUE INDEX idx_chat_rooms_user_pair ON chat_rooms(LEAST(buyer_id, seller_id), GREATEST(buyer_id, seller_id));

-- 买家和卖家快速查询
CREATE INDEX idx_chat_rooms_buyer ON chat_rooms(buyer_id, updated_at DESC);
CREATE INDEX idx_chat_rooms_seller ON chat_rooms(seller_id, updated_at DESC);

-- 活跃聊天室查询
CREATE INDEX idx_chat_rooms_status_updated ON chat_rooms(status, updated_at DESC);

-- 交易关联查询
CREATE INDEX idx_chat_rooms_transaction ON chat_rooms(transaction_id);

-- 最后消息时间查询（聊天列表排序）
CREATE INDEX idx_chat_rooms_last_message_time ON chat_rooms(last_message_time DESC);

-- 2. 聊天消息表索引优化
-- 聊天室消息查询（最重要的查询）
CREATE INDEX idx_chat_messages_room_time ON chat_messages(chat_room_id, sent_at DESC);

-- 发送者消息查询
CREATE INDEX idx_chat_messages_sender_time ON chat_messages(sender_id, sent_at DESC);

-- 消息状态查询（未读消息统计）
CREATE INDEX idx_chat_messages_room_status ON chat_messages(chat_room_id, status);
CREATE INDEX idx_chat_messages_sender_status ON chat_messages(chat_room_id, sender_id, status);

-- 消息类型查询（图片、语音等）
CREATE INDEX idx_chat_messages_type_time ON chat_messages(chat_room_id, message_type, sent_at DESC);

-- 撤回消息查询
CREATE INDEX idx_chat_messages_recalled ON chat_messages(is_recalled, recalled_at);

-- 商品关联消息查询
CREATE INDEX idx_chat_messages_product ON chat_messages(related_product_id, sent_at DESC);

-- 系统消息查询
CREATE INDEX idx_chat_messages_system ON chat_messages(chat_room_id, system_type, sent_at DESC);

-- 消息搜索优化（如果使用FULLTEXT搜索）
-- CREATE FULLTEXT INDEX idx_chat_messages_content_search ON chat_messages(content);

-- 3. 用户表相关索引（如果需要优化聊天室参与者查询）
-- CREATE INDEX idx_users_last_seen ON users(last_seen_at DESC);
-- CREATE INDEX idx_users_status ON users(status);

-- 4. 商品表相关索引（商品讨论功能）
-- CREATE INDEX idx_products_seller_status ON products(seller_id, status);

-- 5. 复合索引优化（针对复杂查询）
-- 聊天室参与者 + 状态 + 时间
CREATE INDEX idx_chat_rooms_participant_active ON chat_rooms(buyer_id, seller_id, status, updated_at DESC);

-- 消息发送者 + 聊天室 + 状态 + 时间（未读消息查询）
CREATE INDEX idx_messages_sender_room_status_time ON chat_messages(sender_id, chat_room_id, status, sent_at DESC);

-- 聊天室 + 消息类型 + 撤回状态（文件消息查询）
CREATE INDEX idx_messages_room_type_recalled ON chat_messages(chat_room_id, message_type, is_recalled);

-- 6. 分区表建议（如果消息量很大）
-- 按月分区聊天消息表
/*
ALTER TABLE chat_messages PARTITION BY RANGE (YEAR(sent_at) * 100 + MONTH(sent_at)) (
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p202502 VALUES LESS THAN (202503),
    PARTITION p202503 VALUES LESS THAN (202504),
    -- ... 继续添加分区
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
*/

-- 7. 查询性能分析
-- 检查索引使用情况
SHOW INDEX FROM chat_rooms;
SHOW INDEX FROM chat_messages;

-- 分析慢查询（示例）
-- EXPLAIN SELECT * FROM chat_rooms WHERE buyer_id = 123 OR seller_id = 123 ORDER BY updated_at DESC;
-- EXPLAIN SELECT * FROM chat_messages WHERE chat_room_id = 456 ORDER BY sent_at DESC LIMIT 20;

-- 8. 索引维护建议
-- 定期优化表
-- OPTIMIZE TABLE chat_rooms;
-- OPTIMIZE TABLE chat_messages;

-- 监控索引使用率
-- SELECT * FROM information_schema.INDEX_STATISTICS WHERE TABLE_SCHEMA = 'fliliy_db';

-- 查看表大小和索引大小
SELECT 
    TABLE_NAME,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS "表大小(MB)",
    ROUND((DATA_LENGTH / 1024 / 1024), 2) AS "数据大小(MB)",
    ROUND((INDEX_LENGTH / 1024 / 1024), 2) AS "索引大小(MB)"
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'fliliy_db' 
AND TABLE_NAME IN ('chat_rooms', 'chat_messages')
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;