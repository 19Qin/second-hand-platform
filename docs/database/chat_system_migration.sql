-- 聊天系统数据库迁移脚本
-- 数据库: fliliy_db
-- 连接信息: localhost:3306, root/123456
-- URL: jdbc:mysql://localhost:3306/fliliy_db?useUnicode=true&characterEncoding=UTF-8&useSSL=false&serverTimezone=Asia/Shanghai
-- 驱动: com.mysql.cj.jdbc.Driver

USE fliliy_db;

-- ================================
-- 检查当前数据库和表结构
-- ================================
SELECT DATABASE() as current_database;
SHOW TABLES;
SELECT TABLE_NAME, TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'fliliy_db' AND TABLE_NAME LIKE '%chat%';

-- 检查依赖表是否存在
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'fliliy_db' AND TABLE_NAME = 'users') 
        THEN 'users表存在' 
        ELSE 'users表不存在，请先创建' 
    END as users_table_status,
    CASE WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'fliliy_db' AND TABLE_NAME = 'products') 
        THEN 'products表存在' 
        ELSE 'products表不存在，请先创建' 
    END as products_table_status;

-- ================================
-- 检查并创建聊天室表
-- ================================
CREATE TABLE IF NOT EXISTS chat_rooms (
    id BIGINT PRIMARY KEY COMMENT '聊天室ID',
    transaction_id BIGINT COMMENT '关联交易ID',
    product_id BIGINT NOT NULL COMMENT '商品ID',
    buyer_id BIGINT NOT NULL COMMENT '买家ID',
    seller_id BIGINT NOT NULL COMMENT '卖家ID',
    
    status ENUM('ACTIVE', 'CLOSED', 'BLOCKED') DEFAULT 'ACTIVE' COMMENT '聊天室状态',
    
    last_message_id BIGINT COMMENT '最后一条消息ID',
    last_message_content TEXT COMMENT '最后消息内容',
    last_message_type ENUM('TEXT', 'IMAGE', 'VOICE', 'SYSTEM') COMMENT '最后消息类型',
    last_message_time TIMESTAMP COMMENT '最后消息时间',
    last_message_sender_id BIGINT COMMENT '最后消息发送者ID',
    
    buyer_unread_count INT DEFAULT 0 COMMENT '买家未读消息数',
    seller_unread_count INT DEFAULT 0 COMMENT '卖家未读消息数',
    total_messages INT DEFAULT 0 COMMENT '消息总数',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (buyer_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES users(id),
    
    UNIQUE KEY uk_product_buyer (product_id, buyer_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_seller_id (seller_id),
    INDEX idx_status (status),
    INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB COMMENT='聊天室表';

-- ================================
-- 检查并创建聊天消息表
-- ================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id BIGINT PRIMARY KEY COMMENT '消息ID，使用雪花算法生成',
    chat_room_id BIGINT NOT NULL COMMENT '聊天室ID',
    sender_id BIGINT COMMENT '发送者ID',
    
    message_type ENUM('TEXT', 'IMAGE', 'VOICE', 'SYSTEM') NOT NULL COMMENT '消息类型',
    content TEXT COMMENT '消息内容',
    
    file_url VARCHAR(500) COMMENT '文件URL',
    thumbnail_url VARCHAR(500) COMMENT '缩略图URL（图片消息）',
    file_size INT COMMENT '文件大小',
    duration INT COMMENT '语音时长（秒）',
    image_width INT COMMENT '图片宽度',
    image_height INT COMMENT '图片高度',
    
    system_type ENUM('TRANSACTION_AGREED', 'TRANSACTION_COMPLETED', 'TRANSACTION_CANCELLED', 'PRODUCT_SOLD') COMMENT '系统消息类型',
    system_data JSON COMMENT '系统消息附加数据',
    
    status ENUM('SENT', 'DELIVERED', 'READ', 'FAILED') DEFAULT 'SENT' COMMENT '消息状态',
    
    is_recalled BOOLEAN DEFAULT FALSE COMMENT '是否已撤回',
    recalled_at TIMESTAMP COMMENT '撤回时间',
    
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP COMMENT '送达时间',
    read_at TIMESTAMP COMMENT '已读时间',
    
    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    
    INDEX idx_chat_room_id (chat_room_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_message_type (message_type),
    INDEX idx_sent_at (sent_at),
    INDEX idx_status (status),
    INDEX idx_is_recalled (is_recalled),
    INDEX idx_room_time (chat_room_id, sent_at),
    INDEX idx_room_status (chat_room_id, status)
) ENGINE=InnoDB COMMENT='聊天消息表';

-- ================================
-- 创建触发器：自动更新聊天室最后消息信息和未读计数
-- ================================
DELIMITER //

DROP TRIGGER IF EXISTS update_chat_room_message_count //

CREATE TRIGGER IF NOT EXISTS update_chat_room_message_count
AFTER INSERT ON chat_messages
FOR EACH ROW
BEGIN
    UPDATE chat_rooms SET 
        total_messages = total_messages + 1,
        last_message_id = NEW.id,
        last_message_content = CASE 
            WHEN NEW.message_type = 'TEXT' THEN NEW.content
            WHEN NEW.message_type = 'IMAGE' THEN '[图片]'
            WHEN NEW.message_type = 'VOICE' THEN '[语音]'
            WHEN NEW.message_type = 'SYSTEM' THEN NEW.content
            ELSE NEW.content
        END,
        last_message_type = NEW.message_type,
        last_message_time = NEW.sent_at,
        last_message_sender_id = NEW.sender_id,
        updated_at = NOW()
    WHERE id = NEW.chat_room_id;
    
    -- 更新未读消息计数（仅对非系统消息）
    IF NEW.sender_id IS NOT NULL AND NEW.message_type != 'SYSTEM' THEN
        IF NEW.sender_id = (SELECT buyer_id FROM chat_rooms WHERE id = NEW.chat_room_id) THEN
            -- 买家发送消息，卖家未读计数+1
            UPDATE chat_rooms SET seller_unread_count = seller_unread_count + 1 WHERE id = NEW.chat_room_id;
        ELSE
            -- 卖家发送消息，买家未读计数+1
            UPDATE chat_rooms SET buyer_unread_count = buyer_unread_count + 1 WHERE id = NEW.chat_room_id;
        END IF;
    END IF;
END //

DELIMITER ;

-- ================================
-- 验证表创建情况
-- ================================
SELECT 
    TABLE_NAME,
    TABLE_COMMENT,
    ENGINE,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'fliliy_db' 
    AND TABLE_NAME IN ('chat_rooms', 'chat_messages')
ORDER BY TABLE_NAME;

-- 显示聊天室表结构
SHOW CREATE TABLE chat_rooms;

-- 显示聊天消息表结构  
SHOW CREATE TABLE chat_messages;

-- 显示触发器
SHOW TRIGGERS LIKE 'chat_%';

COMMIT;

-- ================================
-- 迁移完成提示
-- ================================
SELECT '聊天系统表创建完成！' AS message;
SELECT CONCAT('chat_rooms 表已创建，包含 ', COUNT(*), ' 条记录') AS chat_rooms_status FROM chat_rooms;
SELECT CONCAT('chat_messages 表已创建，包含 ', COUNT(*), ' 条记录') AS chat_messages_status FROM chat_messages;