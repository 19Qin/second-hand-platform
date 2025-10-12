# 前端交易消息处理指南

## 📋 修复说明

后端已修复聊天消息API，现在 `GET /chats/{chatRoomId}/messages` 返回的消息包含：
- ✅ `transactionId` - 交易ID
- ✅ `relatedProductId` - 关联的商品ID
- ✅ `inquiryType` - 咨询类型（PURCHASE/INFO）

---

## 🔑 核心接口

### 1. 获取聊天消息
**接口**: `GET /chats/{chatRoomId}/messages`

**响应示例**:
```json
{
  "success": true,
  "data": {
    "chatInfo": {
      "chatRoomId": 123,
      "participant": { ... },
      "discussedProducts": [ ... ]
    },
    "messages": [
      {
        "id": 1001,
        "senderId": 100,
        "senderName": "买家A",
        "type": "TRANSACTION_REQUEST",
        "content": "发起了交易申请",
        "transactionId": 999,          // ⭐ 交易ID
        "relatedProductId": 456,       // ⭐ 商品ID
        "inquiryType": "PURCHASE",     // ⭐ 咨询类型
        "sentAt": "2025-10-10 10:00:00",
        "isFromMe": true,
        "status": "SENT"
      },
      {
        "id": 1002,
        "senderId": null,
        "senderName": "系统",
        "type": "SYSTEM",
        "content": "交易申请已同意，交易码已生成",
        "transactionId": 999,          // ⭐ 同一个交易
        "relatedProductId": null,
        "sentAt": "2025-10-10 10:05:00",
        "isFromMe": false
      },
      {
        "id": 1003,
        "type": "TRANSACTION_REQUEST",
        "content": "发起了交易申请",
        "transactionId": 888,          // ⭐ 第二次交易（新ID）
        "relatedProductId": 789,       // ⭐ 不同商品
        "inquiryType": "PURCHASE",
        "sentAt": "2025-10-10 11:00:00"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "hasMore": false
    }
  }
}
```

---

## 💡 前端实现方案

### 方案1：按交易ID分组消息（推荐）

```javascript
class ChatMessageManager {
  constructor() {
    this.messages = [];
    this.transactionMap = new Map(); // transactionId -> messages[]
  }

  /**
   * 加载聊天消息
   */
  async loadMessages(chatRoomId) {
    const response = await fetch(`/chats/${chatRoomId}/messages`, {
      headers: { 'Authorization': `Bearer ${this.token}` }
    });
    const data = await response.json();

    this.messages = data.data.messages;
    this.buildTransactionMap();

    return this.messages;
  }

  /**
   * 构建交易消息映射
   */
  buildTransactionMap() {
    this.transactionMap.clear();

    this.messages.forEach(msg => {
      if (msg.transactionId) {
        if (!this.transactionMap.has(msg.transactionId)) {
          this.transactionMap.set(msg.transactionId, []);
        }
        this.transactionMap.get(msg.transactionId).push(msg);
      }
    });
  }

  /**
   * 获取特定交易的所有消息
   */
  getTransactionMessages(transactionId) {
    return this.transactionMap.get(transactionId) || [];
  }

  /**
   * 获取最新的交易申请
   */
  getLatestTransactionRequest() {
    const requests = this.messages.filter(
      m => m.type === 'TRANSACTION_REQUEST'
    );

    if (requests.length === 0) return null;

    // 按发送时间降序排序
    requests.sort((a, b) =>
      new Date(b.sentAt) - new Date(a.sentAt)
    );

    return requests[0];
  }

  /**
   * 检查特定交易的状态
   */
  getTransactionStatus(transactionId) {
    const messages = this.getTransactionMessages(transactionId);

    // 检查是否有"已同意"消息
    const hasAgreed = messages.some(m =>
      m.type === 'SYSTEM' &&
      m.content.includes('已同意')
    );

    if (hasAgreed) return 'AGREED';

    // 检查是否有"已拒绝"消息
    const hasRejected = messages.some(m =>
      m.type === 'SYSTEM' &&
      m.content.includes('已拒绝')
    );

    if (hasRejected) return 'REJECTED';

    // 检查是否有交易申请
    const hasRequest = messages.some(m =>
      m.type === 'TRANSACTION_REQUEST'
    );

    if (hasRequest) return 'PENDING';

    return 'UNKNOWN';
  }

  /**
   * 获取所有交易ID列表
   */
  getAllTransactionIds() {
    return Array.from(this.transactionMap.keys());
  }
}
```

### 方案2：Vue 组件实现示例

```vue
<template>
  <div class="chat-room">
    <!-- 聊天消息列表 -->
    <div class="message-list">
      <div
        v-for="message in messages"
        :key="message.id"
        :class="['message', message.isFromMe ? 'from-me' : 'from-other']"
      >
        <!-- 普通文本消息 -->
        <div v-if="message.type === 'TEXT'" class="text-message">
          {{ message.content }}
        </div>

        <!-- 交易申请消息 -->
        <div
          v-else-if="message.type === 'TRANSACTION_REQUEST'"
          class="transaction-message"
          @click="onTransactionMessageClick(message)"
        >
          <div class="transaction-card">
            <div class="product-info">
              商品ID: {{ message.relatedProductId }}
            </div>
            <div class="transaction-info">
              {{ message.content }}
            </div>
            <div class="transaction-action">
              <button @click.stop="viewTransaction(message.transactionId)">
                查看交易详情
              </button>
            </div>
          </div>
        </div>

        <!-- 系统消息 -->
        <div v-else-if="message.type === 'SYSTEM'" class="system-message">
          {{ message.content }}
          <span v-if="message.transactionId" class="transaction-tag">
            交易#{{ message.transactionId }}
          </span>
        </div>
      </div>
    </div>

    <!-- 当前交易状态栏 -->
    <div v-if="currentTransaction" class="transaction-status-bar">
      <div class="status-info">
        当前交易: #{{ currentTransaction.transactionId }}
        状态: {{ getTransactionStatusText(currentTransaction.transactionId) }}
      </div>
      <button @click="viewTransactionDetail(currentTransaction.transactionId)">
        查看详情
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ChatRoom',
  data() {
    return {
      chatRoomId: null,
      messages: [],
      transactionMap: new Map(),
      currentTransactionId: null
    };
  },
  computed: {
    currentTransaction() {
      if (!this.currentTransactionId) return null;

      const messages = this.transactionMap.get(this.currentTransactionId);
      if (!messages || messages.length === 0) return null;

      return {
        transactionId: this.currentTransactionId,
        messages: messages
      };
    }
  },
  methods: {
    /**
     * 加载聊天消息
     */
    async loadMessages() {
      try {
        const response = await this.$http.get(
          `/chats/${this.chatRoomId}/messages`
        );

        this.messages = response.data.messages;
        this.buildTransactionMap();
        this.updateCurrentTransaction();

      } catch (error) {
        console.error('加载消息失败:', error);
      }
    },

    /**
     * 构建交易消息映射
     */
    buildTransactionMap() {
      this.transactionMap.clear();

      this.messages.forEach(msg => {
        if (msg.transactionId) {
          if (!this.transactionMap.has(msg.transactionId)) {
            this.transactionMap.set(msg.transactionId, []);
          }
          this.transactionMap.get(msg.transactionId).push(msg);
        }
      });

      console.log('交易数量:', this.transactionMap.size);
    },

    /**
     * 更新当前交易
     */
    updateCurrentTransaction() {
      // 找到最新的交易申请消息
      const latestRequest = this.messages
        .filter(m => m.type === 'TRANSACTION_REQUEST')
        .sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt))
        .shift();

      if (latestRequest) {
        this.currentTransactionId = latestRequest.transactionId;
        console.log('当前交易ID:', this.currentTransactionId);
      }
    },

    /**
     * 点击交易消息
     */
    onTransactionMessageClick(message) {
      console.log('点击交易消息:', message.transactionId);
      this.viewTransaction(message.transactionId);
    },

    /**
     * 查看交易详情
     */
    viewTransaction(transactionId) {
      // 跳转到交易详情页
      this.$router.push({
        name: 'TransactionDetail',
        params: { transactionId }
      });
    },

    /**
     * 获取交易状态文本
     */
    getTransactionStatusText(transactionId) {
      const messages = this.transactionMap.get(transactionId) || [];

      // 检查是否已同意
      const hasAgreed = messages.some(m =>
        m.type === 'SYSTEM' && m.content.includes('已同意')
      );
      if (hasAgreed) return '已同意';

      // 检查是否已拒绝
      const hasRejected = messages.some(m =>
        m.type === 'SYSTEM' && m.content.includes('已拒绝')
      );
      if (hasRejected) return '已拒绝';

      // 检查是否有申请
      const hasRequest = messages.some(m =>
        m.type === 'TRANSACTION_REQUEST'
      );
      if (hasRequest) return '等待响应';

      return '未知';
    },

    /**
     * 发起新交易
     */
    async createTransaction(productId) {
      try {
        const response = await this.$http.post('/transactions/request', {
          productId: productId,
          chatRoomId: this.chatRoomId,
          message: '我想购买这个商品'
        });

        const newTransactionId = response.data.transactionId;
        console.log('新交易ID:', newTransactionId);

        // 更新当前交易ID
        this.currentTransactionId = newTransactionId;

        // 重新加载消息
        await this.loadMessages();

      } catch (error) {
        console.error('发起交易失败:', error);
      }
    }
  },
  mounted() {
    this.chatRoomId = this.$route.params.chatRoomId;
    this.loadMessages();
  }
};
</script>
```

### 方案3：React Hooks 实现示例

```javascript
import { useState, useEffect, useCallback } from 'react';

/**
 * 交易消息管理 Hook
 */
function useTransactionMessages(chatRoomId) {
  const [messages, setMessages] = useState([]);
  const [transactionMap, setTransactionMap] = useState(new Map());
  const [currentTransactionId, setCurrentTransactionId] = useState(null);

  /**
   * 加载聊天消息
   */
  const loadMessages = useCallback(async () => {
    try {
      const response = await fetch(`/chats/${chatRoomId}/messages`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await response.json();

      setMessages(data.data.messages);
      buildTransactionMap(data.data.messages);

    } catch (error) {
      console.error('加载消息失败:', error);
    }
  }, [chatRoomId]);

  /**
   * 构建交易消息映射
   */
  const buildTransactionMap = useCallback((messages) => {
    const map = new Map();

    messages.forEach(msg => {
      if (msg.transactionId) {
        if (!map.has(msg.transactionId)) {
          map.set(msg.transactionId, []);
        }
        map.get(msg.transactionId).push(msg);
      }
    });

    setTransactionMap(map);

    // 更新当前交易ID（最新的交易申请）
    const latestRequest = messages
      .filter(m => m.type === 'TRANSACTION_REQUEST')
      .sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt))
      .shift();

    if (latestRequest) {
      setCurrentTransactionId(latestRequest.transactionId);
    }
  }, []);

  /**
   * 获取特定交易的消息
   */
  const getTransactionMessages = useCallback((transactionId) => {
    return transactionMap.get(transactionId) || [];
  }, [transactionMap]);

  /**
   * 获取交易状态
   */
  const getTransactionStatus = useCallback((transactionId) => {
    const messages = getTransactionMessages(transactionId);

    if (messages.some(m => m.type === 'SYSTEM' && m.content.includes('已同意'))) {
      return 'AGREED';
    }
    if (messages.some(m => m.type === 'SYSTEM' && m.content.includes('已拒绝'))) {
      return 'REJECTED';
    }
    if (messages.some(m => m.type === 'TRANSACTION_REQUEST')) {
      return 'PENDING';
    }

    return 'UNKNOWN';
  }, [getTransactionMessages]);

  useEffect(() => {
    loadMessages();
  }, [loadMessages]);

  return {
    messages,
    transactionMap,
    currentTransactionId,
    loadMessages,
    getTransactionMessages,
    getTransactionStatus
  };
}

/**
 * 聊天室组件
 */
function ChatRoom({ chatRoomId }) {
  const {
    messages,
    currentTransactionId,
    getTransactionStatus
  } = useTransactionMessages(chatRoomId);

  const handleTransactionClick = (transactionId) => {
    // 跳转到交易详情页
    navigate(`/transactions/${transactionId}`);
  };

  return (
    <div className="chat-room">
      {/* 当前交易状态 */}
      {currentTransactionId && (
        <div className="transaction-status-bar">
          <span>当前交易: #{currentTransactionId}</span>
          <span>状态: {getTransactionStatus(currentTransactionId)}</span>
          <button onClick={() => handleTransactionClick(currentTransactionId)}>
            查看详情
          </button>
        </div>
      )}

      {/* 消息列表 */}
      <div className="message-list">
        {messages.map(message => (
          <div key={message.id} className="message">
            {message.type === 'TRANSACTION_REQUEST' && (
              <div
                className="transaction-message"
                onClick={() => handleTransactionClick(message.transactionId)}
              >
                <p>{message.content}</p>
                <span>交易 #{message.transactionId}</span>
                <span>商品 #{message.relatedProductId}</span>
              </div>
            )}
            {message.type === 'TEXT' && (
              <div className="text-message">{message.content}</div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## ⚠️ 重要注意事项

### 1. 清除旧缓存
```javascript
// 清除本地存储的旧消息缓存
localStorage.removeItem('chatMessages_' + chatRoomId);

// 清除内存缓存
this.messageCache = {};
```

### 2. 处理 null 值
```javascript
// 旧消息可能没有 transactionId
if (message.transactionId) {
  // 处理交易消息
} else {
  // 普通消息或旧消息
}
```

### 3. WebSocket 消息更新
```javascript
websocket.onmessage = (event) => {
  const message = JSON.parse(event.data);

  // 验证是否是当前交易的消息
  if (message.transactionId === currentTransactionId) {
    handleTransactionUpdate(message);
  }
};
```

---

## 🐛 常见问题排查

### 问题1：看不到 transactionId
**原因**：使用了旧的消息缓存
**解决**：清除缓存，重新加载消息

### 问题2：第二次交易显示第一次的信息
**原因**：前端没有使用 transactionId 区分
**解决**：按照上述方案，使用 transactionId 分组

### 问题3：点击交易消息跳转错误
**原因**：使用了错误的 transactionId
**解决**：从消息的 transactionId 字段获取正确的ID

---

## ✅ 测试清单

- [ ] 能正确显示第一次交易的消息
- [ ] 能正确显示第二次交易的消息
- [ ] 点击交易消息能跳转到正确的交易详情
- [ ] 交易状态显示正确
- [ ] 不会混淆不同的交易
- [ ] WebSocket 消息能正确更新
