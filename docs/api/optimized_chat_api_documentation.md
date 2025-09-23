# 优化后的聊天系统API文档

## 概述

本文档描述了优化后的聊天系统API接口，主要特点：
- **基于用户关系的聊天室**：一个买家与一个卖家只有一个聊天室
- **商品关联消息**：消息可以关联商品，支持在同一聊天室讨论多个商品
- **商品卡片消息**：自动生成商品卡片，提升用户体验
- **智能去重**：避免聊天列表重复显示同一商家

## 基础信息

- **Base URL**: `/api/v1`
- **认证方式**: Bearer Token (JWT)
- **内容类型**: `application/json`

---

## 1. 聊天室管理

### 1.1 开始商品讨论

**接口**: `POST /chat/product-discussion`

**描述**: 点击商品咨询时调用，自动创建或获取聊天室，并发送商品卡片消息

**请求参数**:
```json
{
  "productId": 1234567890,
  "initialMessage": "你好，我对这个商品很感兴趣"  // 可选
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "chatRoom": {
      "id": 1234567890,
      "buyerId": 1001,
      "sellerId": 1002,
      "status": "ACTIVE",
      "otherUser": {
        "id": 1002,
        "username": "seller_001",
        "avatarUrl": "https://example.com/avatar.jpg",
        "isOnline": true
      },
      "unreadCount": 0,
      "totalMessages": 1,
      "lastMessage": {
        "id": 9876543210,
        "type": "PRODUCT_CARD",
        "content": "分享了商品",
        "sentAt": "2025-09-22 15:30:00",
        "isFromMe": true
      },
      "createdAt": "2025-09-22 15:30:00",
      "updatedAt": "2025-09-22 15:30:00"
    },
    "productCard": {
      "id": 9876543210,
      "type": "PRODUCT_CARD",
      "productData": {
        "id": 1234567890,
        "title": "iPhone 14 Pro 256GB",
        "price": 8888.00,
        "imageUrl": "https://example.com/product.jpg",
        "status": "ACTIVE",
        "sellerId": 1002
      },
      "sentAt": "2025-09-22 15:30:00",
      "isFromMe": true
    }
  }
}
```

### 1.2 获取聊天列表

**接口**: `GET /chat/rooms`

**描述**: 获取用户的聊天室列表

**请求参数**:
- `page`: 页码，默认1
- `size`: 每页数量，默认20

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "rooms": [
      {
        "id": 1234567890,
        "otherUser": {
          "id": 1002,
          "username": "seller_001",
          "avatarUrl": "https://example.com/avatar.jpg",
          "isOnline": true,
          "lastOnlineTime": "2025-09-22 15:25:00"
        },
        "lastMessage": {
          "id": 9876543210,
          "type": "TEXT",
          "content": "好的，明天下午见面交易",
          "sentAt": "2025-09-22 15:25:00",
          "isFromMe": false
        },
        "unreadCount": 2,
        "totalMessages": 15,
        "discussedProducts": [
          {
            "id": 1234567890,
            "title": "iPhone 14 Pro 256GB",
            "imageUrl": "https://example.com/product.jpg"
          }
        ],
        "updatedAt": "2025-09-22 15:25:00"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "hasNext": true
    },
    "totalUnreadCount": 8
  }
}
```

### 1.3 获取聊天室详情

**接口**: `GET /chat/rooms/{roomId}`

**描述**: 获取指定聊天室的详细信息

**路径参数**:
- `roomId`: 聊天室ID

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1234567890,
    "buyerId": 1001,
    "sellerId": 1002,
    "status": "ACTIVE",
    "otherUser": {
      "id": 1002,
      "username": "seller_001",
      "avatarUrl": "https://example.com/avatar.jpg",
      "isOnline": true,
      "lastOnlineTime": "2025-09-22 15:25:00"
    },
    "discussedProducts": [
      {
        "id": 1234567890,
        "title": "iPhone 14 Pro 256GB",
        "price": 8888.00,
        "imageUrl": "https://example.com/product.jpg",
        "status": "ACTIVE"
      }
    ],
    "unreadCount": 2,
    "totalMessages": 15,
    "createdAt": "2025-09-20 10:30:00",
    "updatedAt": "2025-09-22 15:25:00"
  }
}
```

---

## 2. 消息管理

### 2.1 获取聊天记录

**接口**: `GET /chat/rooms/{roomId}/messages`

**描述**: 获取聊天室的消息记录（支持分页和时间范围查询）

**路径参数**:
- `roomId`: 聊天室ID

**请求参数**:
- `page`: 页码，默认1
- `size`: 每页数量，默认20
- `before`: 获取指定时间之前的消息（ISO格式）
- `productId`: 筛选与指定商品相关的消息

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "messages": [
      {
        "id": 9876543210,
        "senderId": 1002,
        "type": "TEXT",
        "content": "好的，明天下午见面交易",
        "relatedProductId": 1234567890,
        "sentAt": "2025-09-22 15:25:00",
        "status": "READ",
        "isFromMe": false,
        "isRecalled": false
      },
      {
        "id": 9876543211,
        "senderId": 1001,
        "type": "PRODUCT_CARD",
        "content": "分享了商品",
        "productData": {
          "id": 1234567890,
          "title": "iPhone 14 Pro 256GB",
          "price": 8888.00,
          "imageUrl": "https://example.com/product.jpg",
          "status": "ACTIVE"
        },
        "sentAt": "2025-09-22 14:20:00",
        "isFromMe": true
      },
      {
        "id": 9876543212,
        "senderId": 1002,
        "type": "IMAGE",
        "content": "https://example.com/chat-image.jpg",
        "thumbnail": "https://example.com/chat-image-thumb.jpg",
        "imageWidth": 800,
        "imageHeight": 600,
        "fileSize": 245760,
        "sentAt": "2025-09-22 14:15:00",
        "status": "READ",
        "isFromMe": false
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "hasNext": true
    }
  }
}
```

### 2.2 发送消息

**接口**: `POST /chat/rooms/{roomId}/messages`

**描述**: 在聊天室中发送消息

**路径参数**:
- `roomId`: 聊天室ID

**请求参数**:

**文本消息**:
```json
{
  "type": "TEXT",
  "content": "你好，商品还在吗？",
  "relatedProductId": 1234567890  // 可选，关联商品
}
```

**图片消息**:
```json
{
  "type": "IMAGE",
  "content": "https://example.com/uploaded-image.jpg",
  "thumbnail": "https://example.com/uploaded-image-thumb.jpg",
  "imageWidth": 800,
  "imageHeight": 600,
  "fileSize": 245760
}
```

**语音消息**:
```json
{
  "type": "VOICE",
  "content": "https://example.com/voice-message.mp3",
  "duration": 15,
  "fileSize": 128000
}
```

**商品卡片消息**:
```json
{
  "type": "PRODUCT_CARD",
  "productId": 1234567890
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 9876543213,
    "senderId": 1001,
    "type": "TEXT",
    "content": "你好，商品还在吗？",
    "relatedProductId": 1234567890,
    "sentAt": "2025-09-22 15:30:00",
    "status": "SENT",
    "isFromMe": true
  }
}
```

### 2.3 标记消息已读

**接口**: `POST /chat/rooms/{roomId}/read`

**描述**: 标记聊天室的消息为已读

**路径参数**:
- `roomId`: 聊天室ID

**响应示例**:
```json
{
  "code": 200,
  "message": "消息已标记为已读",
  "data": {
    "unreadCount": 0
  }
}
```

### 2.4 撤回消息

**接口**: `POST /chat/messages/{messageId}/recall`

**描述**: 撤回消息（2分钟内有效）

**路径参数**:
- `messageId`: 消息ID

**响应示例**:
```json
{
  "code": 200,
  "message": "消息撤回成功",
  "data": {
    "recalled": true
  }
}
```

---

## 3. 商品相关功能

### 3.1 获取聊天室讨论的商品

**接口**: `GET /chat/rooms/{roomId}/products`

**描述**: 获取聊天室中讨论过的所有商品

**路径参数**:
- `roomId`: 聊天室ID

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "products": [
      {
        "id": 1234567890,
        "title": "iPhone 14 Pro 256GB",
        "price": 8888.00,
        "imageUrl": "https://example.com/product.jpg",
        "status": "ACTIVE",
        "lastDiscussedAt": "2025-09-22 15:25:00"
      },
      {
        "id": 1234567891,
        "title": "MacBook Pro 16英寸",
        "price": 18888.00,
        "imageUrl": "https://example.com/macbook.jpg",
        "status": "ACTIVE",
        "lastDiscussedAt": "2025-09-21 10:15:00"
      }
    ]
  }
}
```

### 3.2 搜索聊天记录

**接口**: `GET /chat/rooms/{roomId}/search`

**描述**: 在聊天记录中搜索关键词

**路径参数**:
- `roomId`: 聊天室ID

**请求参数**:
- `keyword`: 搜索关键词
- `type`: 搜索类型（text/product），默认all

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "results": [
      {
        "id": 9876543210,
        "senderId": 1002,
        "type": "TEXT",
        "content": "iPhone 14的价格还能商量吗？",
        "highlightContent": "<mark>iPhone 14</mark>的价格还能商量吗？",
        "relatedProductId": 1234567890,
        "sentAt": "2025-09-22 14:20:00",
        "isFromMe": false
      }
    ],
    "totalCount": 3
  }
}
```

---

## 4. WebSocket 实时通信

### 4.1 连接建立

**连接地址**: `ws://localhost:8080/api/v1/ws/chat`

**连接参数**:
- `token`: JWT认证token

### 4.2 消息格式

**发送消息**:
```json
{
  "action": "SEND_MESSAGE",
  "chatRoomId": 1234567890,
  "data": {
    "type": "TEXT",
    "content": "你好",
    "relatedProductId": 1234567890
  }
}
```

**接收消息**:
```json
{
  "type": "NEW_MESSAGE",
  "chatRoomId": 1234567890,
  "message": {
    "id": 9876543214,
    "senderId": 1002,
    "type": "TEXT",
    "content": "你好，商品还在的",
    "sentAt": "2025-09-22 15:35:00",
    "isFromMe": false
  }
}
```

**用户状态通知**:
```json
{
  "type": "USER_STATUS",
  "userId": 1002,
  "status": "ONLINE"
}
```

---

## 5. 错误码说明

| 错误码 | 说明 |
|--------|------|
| 4001 | 聊天室不存在 |
| 4002 | 无权限访问聊天室 |
| 4003 | 不能与自己聊天 |
| 4004 | 商品不存在 |
| 4005 | 消息不存在或无法撤回 |
| 4006 | 聊天室已关闭 |
| 4007 | 消息发送失败 |
| 5001 | 服务器内部错误 |

---

## 6. 使用场景示例

### 6.1 用户浏览商品并咨询

1. 用户在商品详情页点击"立即咨询"
2. 前端调用 `POST /chat/product-discussion` 接口
3. 系统自动创建或获取聊天室，发送商品卡片
4. 跳转到聊天界面，显示商品卡片和聊天记录

### 6.2 用户查看聊天列表

1. 用户打开聊天列表页面
2. 调用 `GET /chat/rooms` 接口获取聊天列表
3. 显示与每个商家的对话，包括最后消息和未读数量
4. 用户点击某个聊天项进入具体聊天室

### 6.3 聊天室内多商品讨论

1. 在聊天室中，用户可以通过商品卡片消息分享新商品
2. 系统自动关联消息与商品，方便后续查找
3. 可以通过商品筛选查看特定商品的讨论记录

### 6.4 实时聊天体验

1. 建立WebSocket连接
2. 接收实时消息推送
3. 显示对方在线状态
4. 支持消息送达和已读状态同步

---

## 7. 优化特性说明

### 7.1 聊天室合并优化

- **问题**: 原来一个商品一个聊天室，导致同一商家出现多次
- **解决**: 基于买家-卖家关系建立聊天室，一对用户只有一个聊天室
- **效果**: 聊天列表清晰，用户体验更佳

### 7.2 商品关联功能

- **商品卡片**: 首次讨论商品时自动发送商品卡片
- **消息关联**: 消息可以关联具体商品，便于分类查看
- **商品快照**: 保存商品历史状态，防止信息丢失

### 7.3 智能化体验

- **自动去重**: 避免重复发送相同商品的卡片
- **上下文保持**: 在同一聊天室可以无缝切换讨论不同商品
- **历史追溯**: 完整保留商品讨论历史

这套API设计充分考虑了用户体验和系统性能，提供了完整的聊天功能同时解决了原有系统的核心问题。