-- ===============================================
-- 优化后的聊天系统数据库设计
-- 基于用户关系而非商品的聊天室模型
-- ===============================================

-- 聊天室表
CREATE TABLE chat_rooms (
    id BIGINT PRIMARY KEY,
    transaction_id BIGINT,
    buyer_id BIGINT NOT NULL COMMENT '买家ID',
    seller_id BIGINT NOT NULL COMMENT '卖家ID',
    status ENUM('ACTIVE', 'CLOSED', 'BLOCKED') DEFAULT 'ACTIVE' COMMENT '聊天室状态',
    last_message_id BIGINT COMMENT '最后一条消息ID',
    last_message_content TEXT COMMENT '最后一条消息内容',
    last_message_type ENUM('TEXT', 'IMAGE', 'VOICE', 'SYSTEM', 'PRODUCT_CARD') COMMENT '最后一条消息类型',
    last_message_time TIMESTAMP COMMENT '最后一条消息时间',
    last_message_sender_id BIGINT COMMENT '最后一条消息发送者ID',
    buyer_unread_count INT DEFAULT 0 COMMENT '买家未读消息数',
    seller_unread_count INT DEFAULT 0 COMMENT '卖家未读消息数',
    total_messages INT DEFAULT 0 COMMENT '消息总数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    -- 唯一约束：一个买家和一个卖家只能有一个聊天室
    UNIQUE KEY uk_buyer_seller (buyer_id, seller_id),
    
    -- 索引优化
    KEY idx_buyer_id (buyer_id),
    KEY idx_seller_id (seller_id),
    KEY idx_updated_at (updated_at),
    KEY idx_transaction_id (transaction_id),
    KEY idx_status (status),
    
    -- 外键约束
    FOREIGN KEY (buyer_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES users(id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)
) COMMENT='聊天室表 - 基于买家和卖家的一对一聊天';

-- 聊天消息表
CREATE TABLE chat_messages (
    id BIGINT PRIMARY KEY,
    chat_room_id BIGINT NOT NULL COMMENT '聊天室ID',
    sender_id BIGINT NOT NULL COMMENT '发送者ID',
    message_type ENUM('TEXT', 'IMAGE', 'VOICE', 'SYSTEM', 'PRODUCT_CARD') NOT NULL COMMENT '消息类型',
    content TEXT COMMENT '消息内容',
    
    -- 文件相关字段（图片/语音）
    file_url VARCHAR(500) COMMENT '文件URL',
    thumbnail_url VARCHAR(500) COMMENT '缩略图URL',
    file_size INT COMMENT '文件大小（字节）',
    duration INT COMMENT '语音时长（秒）',
    image_width INT COMMENT '图片宽度',
    image_height INT COMMENT '图片高度',
    
    -- 系统消息相关
    system_type ENUM('TRANSACTION_AGREED', 'TRANSACTION_COMPLETED', 'TRANSACTION_CANCELLED', 'PRODUCT_SOLD') COMMENT '系统消息类型',
    system_data JSON COMMENT '系统消息数据',
    
    -- 商品关联字段（新增）
    related_product_id BIGINT COMMENT '关联商品ID',
    product_snapshot JSON COMMENT '商品快照数据',
    
    -- 消息状态
    status ENUM('SENT', 'DELIVERED', 'READ', 'FAILED') DEFAULT 'SENT' COMMENT '消息状态',
    
    -- 撤回相关
    is_recalled TINYINT(1) DEFAULT 0 COMMENT '是否已撤回',
    recalled_at TIMESTAMP NULL COMMENT '撤回时间',
    
    -- 时间字段
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    delivered_at TIMESTAMP NULL COMMENT '送达时间',
    read_at TIMESTAMP NULL COMMENT '已读时间',
    
    -- 索引优化
    KEY idx_chat_room_id (chat_room_id),
    KEY idx_sender_id (sender_id),
    KEY idx_message_type (message_type),
    KEY idx_status (status),
    KEY idx_is_recalled (is_recalled),
    KEY idx_sent_at (sent_at),
    KEY idx_related_product (related_product_id),
    KEY idx_chat_room_sent_at (chat_room_id, sent_at DESC),
    
    -- 外键约束
    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id),
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (related_product_id) REFERENCES products(id)
) COMMENT='聊天消息表 - 支持多种消息类型和商品关联';

-- ===============================================
-- 核心设计特点
-- ===============================================

/*
1. 聊天室设计优化：
   - 以用户关系为核心：buyer_id + seller_id 唯一标识
   - 移除 product_id 字段，避免聊天室碎片化
   - 通过 uk_buyer_seller 唯一约束确保一对用户只有一个聊天室

2. 消息关联优化：
   - 添加 related_product_id 字段，支持消息与商品的关联
   - 添加 product_snapshot 字段，保存商品历史状态
   - 新增 PRODUCT_CARD 消息类型，支持商品卡片展示

3. 性能优化：
   - 减少聊天室数量，提升查询效率
   - 优化索引设计，支持高效的分页和排序
   - 支持按时间范围、商品ID等多维度查询

4. 用户体验优化：
   - 聊天列表按用户关系展示，避免重复显示同一商家
   - 支持在同一聊天室讨论多个商品
   - 智能商品卡片，首次讨论时自动生成

5. 数据完整性：
   - 完整的外键约束确保数据一致性
   - 商品快照功能防止商品信息变更导致的历史记录错乱
   - 支持消息撤回、已读状态等完整的聊天功能
*/

-- ===============================================
-- 常用查询示例
-- ===============================================

-- 1. 获取用户的聊天列表（按最后消息时间排序）
SELECT cr.*, 
       b.username as buyer_name,
       s.username as seller_name
FROM chat_rooms cr
LEFT JOIN users b ON cr.buyer_id = b.id
LEFT JOIN users s ON cr.seller_id = s.id
WHERE cr.buyer_id = ? OR cr.seller_id = ?
ORDER BY cr.updated_at DESC;

-- 2. 获取聊天室的消息记录（分页）
SELECT cm.*,
       u.username as sender_name,
       u.avatar_url as sender_avatar
FROM chat_messages cm
LEFT JOIN users u ON cm.sender_id = u.id
WHERE cm.chat_room_id = ?
ORDER BY cm.sent_at DESC
LIMIT ? OFFSET ?;

-- 3. 获取聊天室讨论过的商品列表
SELECT DISTINCT cm.related_product_id,
       JSON_EXTRACT(cm.product_snapshot, '$.title') as product_title,
       JSON_EXTRACT(cm.product_snapshot, '$.price') as product_price,
       JSON_EXTRACT(cm.product_snapshot, '$.imageUrl') as product_image
FROM chat_messages cm
WHERE cm.chat_room_id = ? 
AND cm.related_product_id IS NOT NULL;

-- 4. 搜索聊天记录中提到的商品
SELECT cm.*, 
       JSON_EXTRACT(cm.product_snapshot, '$.title') as product_title
FROM chat_messages cm
WHERE cm.chat_room_id = ?
AND (cm.content LIKE ? OR JSON_EXTRACT(cm.product_snapshot, '$.title') LIKE ?);

-- 5. 获取用户的总未读消息数
SELECT SUM(
    CASE 
        WHEN cr.buyer_id = ? THEN cr.buyer_unread_count 
        ELSE cr.seller_unread_count 
    END
) as total_unread
FROM chat_rooms cr
WHERE cr.buyer_id = ? OR cr.seller_id = ?;

-- ===============================================
-- 数据维护建议
-- ===============================================

/*
1. 定期清理：
   - 定期清理已删除用户的聊天记录
   - 清理超过保留期限的撤回消息
   - 压缩或归档历史聊天数据

2. 性能监控：
   - 监控聊天室表和消息表的增长情况
   - 定期分析慢查询并优化索引
   - 考虑按时间分区存储历史消息

3. 数据备份：
   - 定期备份聊天数据，确保数据安全
   - 制定数据恢复策略
   - 测试备份数据的完整性
*/