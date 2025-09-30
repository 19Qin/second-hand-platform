-- =============================================
-- 交易模块重构 - 数据库变更脚本
-- 日期: 2025-10-01
-- 版本: v2.0
-- 状态: ✅ 已测试通过
-- =============================================

-- 注意事项：
-- 1. 执行前请备份数据库
-- 2. 建议在测试环境先执行验证
-- 3. 生产环境请在低峰期执行

USE fliliy_db;

-- =============================================
-- 1. transactions 表变更（已在之前的迁移中完成，此处列出供参考）
-- =============================================

-- 新增字段（如果不存在）
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS request_by BIGINT COMMENT '交易申请发起方',
ADD COLUMN IF NOT EXISTS requested_at TIMESTAMP NULL COMMENT '交易申请发起时间',
ADD COLUMN IF NOT EXISTS responded_at TIMESTAMP NULL COMMENT '交易申请响应时间',
ADD COLUMN IF NOT EXISTS reject_reason VARCHAR(500) COMMENT '拒绝原因',
ADD COLUMN IF NOT EXISTS code_refresh_count INT DEFAULT 0 COMMENT '交易码刷新次数';

-- 修改状态枚举（添加新状态）
ALTER TABLE transactions
MODIFY COLUMN status ENUM('INQUIRY','PENDING','AGREED','COMPLETED','REJECTED','CANCELLED','EXPIRED')
DEFAULT 'PENDING' COMMENT '交易状态';

-- =============================================
-- 2. chat_messages 表变更
-- =============================================

-- 新增字段（如果不存在）
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS transaction_id BIGINT COMMENT '关联的交易ID',
ADD COLUMN IF NOT EXISTS inquiry_type VARCHAR(20) COMMENT '交易意向类型';

-- 修改消息类型枚举（添加交易相关消息类型）
ALTER TABLE chat_messages
MODIFY COLUMN message_type ENUM('TEXT','IMAGE','VOICE','SYSTEM','PRODUCT_CARD','TRANSACTION_REQUEST','TRANSACTION_RESPONSE')
NOT NULL COMMENT '消息类型';

-- **重要修改**：允许 sender_id 为 NULL（用于系统消息）
ALTER TABLE chat_messages
MODIFY COLUMN sender_id BIGINT(20) NULL COMMENT '发送者ID，NULL表示系统消息';

-- =============================================
-- 3. chat_rooms 表变更
-- =============================================

-- 修改最后消息类型枚举（添加交易相关消息类型）
ALTER TABLE chat_rooms
MODIFY COLUMN last_message_type ENUM('TEXT','IMAGE','VOICE','SYSTEM','PRODUCT_CARD','TRANSACTION_REQUEST','TRANSACTION_RESPONSE')
COMMENT '最后一条消息类型';

-- =============================================
-- 4. 数据迁移（可选）
-- =============================================

-- 将旧的 INQUIRY 状态数据迁移为 PENDING
UPDATE transactions
SET status = 'PENDING'
WHERE status = 'INQUIRY';

-- =============================================
-- 5. 验证脚本
-- =============================================

-- 验证 transactions 表结构
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'fliliy_db'
  AND TABLE_NAME = 'transactions'
  AND COLUMN_NAME IN ('request_by', 'requested_at', 'responded_at', 'reject_reason', 'code_refresh_count', 'status');

-- 验证 chat_messages 表结构
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'fliliy_db'
  AND TABLE_NAME = 'chat_messages'
  AND COLUMN_NAME IN ('transaction_id', 'inquiry_type', 'message_type', 'sender_id');

-- 验证 chat_rooms 表结构
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'fliliy_db'
  AND TABLE_NAME = 'chat_rooms'
  AND COLUMN_NAME = 'last_message_type';

-- =============================================
-- 执行结果检查
-- =============================================

-- 检查是否有交易数据
SELECT
    status,
    COUNT(*) as count
FROM transactions
GROUP BY status;

-- 检查新增的交易申请数据
SELECT
    id,
    buyer_id,
    seller_id,
    status,
    request_by,
    requested_at,
    responded_at
FROM transactions
WHERE requested_at IS NOT NULL
ORDER BY requested_at DESC
LIMIT 5;

-- =============================================
-- 完成
-- =============================================

SELECT '✅ 交易模块数据库变更脚本执行完成' AS result;