# 交易模块 API 文档 v2.0

**更新时间**: 2025-10-01
**Base URL**: `http://localhost:8080/api/v1`
**认证方式**: Bearer Token (JWT)

---

## 一、新增接口

### 1.1 发起交易申请 ✨NEW

**接口**: `POST /transactions/request`
**权限**: 需要登录（USER角色）
**描述**: 买家在聊天后发起正式的交易申请

**请求头**:
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**请求参数**:
```json
{
  "chatRoomId": 1971547214450921472,  // 必填，聊天室ID
  "productId": 1969757587893260288,   // 必填，商品ID
  "message": "你好，我想购买这个商品"  // 可选，附加消息
}
```

**响应示例（成功）**:
```json
{
  "code": 200,
  "message": "交易申请已发送",
  "data": {
    "transactionId": "tx_1973059915022995456",
    "status": "PENDING",
    "requestedAt": "2025-10-01 00:18:36",
    "message": "交易申请已发送，等待对方响应"
  },
  "timestamp": 1759249116127
}
```

**业务逻辑**:
1. 验证聊天室权限（只有参与者可以发起）
2. 验证商品状态（必须是ACTIVE）
3. 验证不能购买自己的商品
4. 检查是否已有进行中的交易
5. 创建交易记录（status=PENDING）
6. 在聊天室发送TRANSACTION_REQUEST类型消息

**错误响应**:
```json
{
  "code": 500,
  "message": "商品不可交易 / 已存在进行中的交易申请 / 无权限访问此聊天室",
  "data": null
}
```

---

### 1.2 响应交易申请 ✨NEW

**接口**: `POST /transactions/{transactionId}/respond`
**权限**: 需要登录（USER角色）
**描述**: 卖家响应买家的交易申请（同意或拒绝）

**请求头**:
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**路径参数**:
- `transactionId`: 交易ID（如：tx_1973059915022995456）

#### 1.2.1 同意交易

**请求参数**:
```json
{
  "action": "AGREE"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "交易申请已同意",
  "data": {
    "transactionId": "tx_1973059915022995456",
    "status": "AGREED",
    "transactionCode": "0894",              // 4位交易码
    "codeExpiresAt": "2025-10-02 00:19:51", // 24小时后过期（自动刷新）
    "note": "请在线下交易时向卖家提供此交易码",
    "message": "交易申请已同意"
  }
}
```

#### 1.2.2 拒绝交易

**请求参数**:
```json
{
  "action": "REJECT",
  "reason": "抱歉，商品已售出"  // 必填，拒绝原因
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "交易申请已拒绝",
  "data": {
    "transactionId": "tx_1973060570131337216",
    "status": "REJECTED",
    "transactionCode": null,
    "codeExpiresAt": null,
    "note": null,
    "message": "交易申请已拒绝"
  }
}
```

**业务逻辑**:
1. 验证交易存在
2. 验证权限（只有对方可以响应，不能响应自己的申请）
3. 验证交易状态（必须是PENDING）
4. **同意**：生成4位交易码，有效期24小时，发送系统消息
5. **拒绝**：记录拒绝原因，发送系统消息

**错误响应**:
```json
{
  "code": 500,
  "message": "交易不存在 / 无权限操作此交易 / 不能响应自己发起的交易申请 / 交易状态不正确",
  "data": null
}
```

---

### 1.3 完成交易（保持不变）

**接口**: `POST /transactions/{transactionId}/complete`
**权限**: 需要登录（USER角色）
**描述**: 卖家输入交易码完成交易

**请求参数**:
```json
{
  "transactionCode": "0894",             // 必填，买家提供的4位交易码
  "rating": 5,                           // 可选，评分1-5
  "feedback": "非常好的买家，交易顺利！"  // 可选，评价文字
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "交易确认成功",
  "data": {
    "transactionId": "tx_1973059915022995456",
    "status": "COMPLETED",
    "completedAt": "2025-10-01 00:20:30",
    "productStatus": "SOLD"
  }
}
```

**业务逻辑**:
1. 验证权限（只有卖家可以完成交易）
2. 验证交易状态（必须是AGREED）
3. 验证交易码是否正确
4. 验证交易码是否过期
5. 更新交易状态为COMPLETED
6. 更新商品状态为SOLD
7. 发送交易完成系统消息

---

## 二、废弃接口 ⚠️

以下接口已废弃，请使用新接口替代：

| 废弃接口 | 替代接口 | 说明 |
|---------|---------|------|
| `POST /transactions/inquiry` | `POST /transactions/request` | 发起交易申请 |
| `POST /transactions/{id}/agree-offline` | `POST /transactions/{id}/respond` | 响应交易申请 |

---

## 三、交易状态说明

### 3.1 状态枚举

```java
public enum TransactionStatus {
    INQUIRY,      // 咨询中（废弃，兼容旧数据）
    PENDING,      // 待响应（已发起交易申请，等待对方同意/拒绝）✨NEW
    AGREED,       // 已同意（对方同意交易，已生成交易码）
    COMPLETED,    // 交易完成
    REJECTED,     // 已拒绝（对方拒绝了交易申请）✨NEW
    CANCELLED,    // 已取消
    EXPIRED       // 已过期
}
```

### 3.2 状态流转图

```
聊天咨询
    ↓
PENDING（发起交易申请）
    ↓
    ├─→ AGREED（同意） → COMPLETED（完成交易）
    └─→ REJECTED（拒绝）
```

---

## 四、WebSocket消息类型

### 4.1 交易申请消息 ✨NEW

**消息类型**: `TRANSACTION_REQUEST`

**消息结构**:
```json
{
  "id": "1973059915022995456",
  "chatRoomId": 1971547214450921472,
  "senderId": 1962950810434408448,
  "messageType": "TRANSACTION_REQUEST",
  "content": "你好，我想购买这个iPhone 15 Pro Max",
  "transactionId": 1973059915022995456,
  "inquiryType": "PURCHASE",
  "relatedProductId": 1969757587893260288,
  "sentAt": "2025-10-01 00:18:36",
  "status": "SENT"
}
```

**前端处理**:
- 卖家端：显示交易申请卡片，包含"同意/拒绝"按钮
- 买家端：显示"等待对方响应"状态

---

### 4.2 交易响应消息 ✨NEW

#### 4.2.1 同意消息

**消息类型**: `SYSTEM`
**系统消息类型**: `TRANSACTION_AGREED`

```json
{
  "id": "...",
  "chatRoomId": 1971547214450921472,
  "senderId": null,
  "messageType": "SYSTEM",
  "systemType": "TRANSACTION_AGREED",
  "content": "交易申请已同意，交易码已生成",
  "transactionId": 1973059915022995456,
  "sentAt": "2025-10-01 00:19:52"
}
```

**前端处理**:
- 买家端：显示交易码（大字显示）
- 卖家端：显示"交易已同意，等待买家提供交易码"

#### 4.2.2 拒绝消息

**消息类型**: `SYSTEM`
**系统消息类型**: `TRANSACTION_REJECTED`

```json
{
  "id": "...",
  "chatRoomId": 1971547214450921472,
  "senderId": null,
  "messageType": "SYSTEM",
  "systemType": "TRANSACTION_REJECTED",
  "content": "交易申请已被拒绝：抱歉，商品已售出",
  "transactionId": 1973060570131337216,
  "sentAt": "2025-10-01 00:21:24"
}
```

---

### 4.3 交易完成消息

**消息类型**: `SYSTEM`
**系统消息类型**: `TRANSACTION_COMPLETED`

```json
{
  "id": "...",
  "chatRoomId": 1971547214450921472,
  "senderId": null,
  "messageType": "SYSTEM",
  "systemType": "TRANSACTION_COMPLETED",
  "content": "交易已完成！感谢使用Fliliy二手交易平台",
  "transactionId": 1973059915022995456,
  "sentAt": "2025-10-01 00:20:31"
}
```

---

## 五、前端开发指南

### 5.1 聊天页面改造

#### 买家端

1. **发起交易按钮**
   - 位置：聊天输入框上方或商品卡片上
   - 文案："发起交易申请"
   - 点击后调用 `POST /transactions/request`

2. **交易申请状态**
   - 状态一：PENDING - 显示"等待卖家响应"
   - 状态二：AGREED - **大字显示交易码**，提示"请在线下交易时将此交易码告诉卖家"
   - 状态三：REJECTED - 显示"交易申请被拒绝"及原因
   - 状态四：COMPLETED - 显示"交易已完成"

#### 卖家端

1. **交易申请卡片**
   - 显示买家信息
   - 显示商品信息
   - 两个按钮："同意"和"拒绝"

2. **同意后**
   - 显示"等待买家提供交易码"
   - 添加"输入交易码完成交易"按钮

3. **交易码输入界面**
   - 4位数字输入框（大字显示）
   - "完成交易"按钮
   - 可选：评分和评价

---

### 5.2 页面示例

#### 买家发起交易

```javascript
// 发起交易申请
async function createTransactionRequest(chatRoomId, productId, message) {
  const response = await fetch('/api/v1/transactions/request', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      chatRoomId,
      productId,
      message
    })
  });

  const result = await response.json();
  if (result.code === 200) {
    // 显示"交易申请已发送"提示
    showTransactionStatus('PENDING');
  }
}
```

#### 卖家响应交易

```javascript
// 同意交易
async function agreeTransaction(transactionId) {
  const response = await fetch(`/api/v1/transactions/${transactionId}/respond`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      action: 'AGREE'
    })
  });

  const result = await response.json();
  if (result.code === 200) {
    // 显示"交易已同意，等待买家提供交易码"
    showTransactionAgreed();
  }
}

// 拒绝交易
async function rejectTransaction(transactionId, reason) {
  const response = await fetch(`/api/v1/transactions/${transactionId}/respond`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      action: 'REJECT',
      reason
    })
  });

  const result = await response.json();
  if (result.code === 200) {
    // 显示"交易已拒绝"
    showTransactionRejected();
  }
}
```

#### 卖家完成交易

```javascript
// 完成交易
async function completeTransaction(transactionId, transactionCode, rating, feedback) {
  const response = await fetch(`/api/v1/transactions/${transactionId}/complete`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      transactionCode,
      rating,
      feedback
    })
  });

  const result = await response.json();
  if (result.code === 200) {
    // 显示"交易完成"
    showTransactionCompleted();
  } else if (result.code === 500 && result.message.includes('交易验证码错误')) {
    // 显示"交易码错误，请重新输入"
    showError('交易码错误');
  }
}
```

---

### 5.3 WebSocket消息处理

```javascript
// 处理交易申请消息
function handleTransactionRequestMessage(message) {
  if (message.messageType === 'TRANSACTION_REQUEST') {
    // 显示交易申请卡片（仅卖家端）
    if (isSeller) {
      showTransactionRequestCard({
        transactionId: message.transactionId,
        buyer: message.sender,
        product: message.relatedProduct,
        message: message.content
      });
    } else {
      // 买家端显示"交易申请已发送"
      showTransactionPending();
    }
  }
}

// 处理系统消息
function handleSystemMessage(message) {
  if (message.systemType === 'TRANSACTION_AGREED') {
    // 买家端：显示交易码
    // 卖家端：显示"等待买家提供交易码"
    handleTransactionAgreed(message.transactionId);
  } else if (message.systemType === 'TRANSACTION_REJECTED') {
    // 显示"交易已拒绝"
    handleTransactionRejected(message.content);
  } else if (message.systemType === 'TRANSACTION_COMPLETED') {
    // 显示"交易已完成"
    handleTransactionCompleted();
  }
}
```

---

## 六、注意事项

### 6.1 交易码机制

- ✅ 交易码为4位数字（0000-9999）
- ✅ 有效期24小时
- ✅ 每日凌晨1点自动刷新（不会失效）
- ✅ 买家需将交易码口头告知卖家
- ✅ 卖家输入交易码完成交易

### 6.2 安全性

- ✅ 所有交易接口都需要登录认证
- ✅ 权限验证：不能响应自己发起的申请
- ✅ 状态验证：只能在特定状态下进行操作
- ✅ 交易码验证：防止恶意完成交易

### 6.3 业务规则

- ✅ 同一商品同一买家只能有一个进行中的交易
- ✅ 交易完成后商品自动变为已售出
- ✅ 拒绝的交易可以重新发起
- ✅ 已完成的交易不可修改

---

## 七、测试数据

### 7.1 测试用户

- 买家: 13800138999 (userId: 1962950810434408448)
- 卖家: 13800138000 (userId: 1959106057909440512)

### 7.2 测试商品

- iPhone 15 Pro Max (productId: 1969757587893260288)
- 小米13 Ultra (productId: 1969757702427119616)

### 7.3 测试聊天室

- chatRoomId: 1971547214450921472

---

## 八、常见问题

### Q1: 交易码过期了怎么办？

A: 交易码不会过期，每24小时自动刷新为新的交易码。买家可以在交易详情中查看最新的交易码。

### Q2: 如果买家忘记交易码怎么办？

A: 买家可以在交易详情页重新查看交易码，或者在聊天记录中找到系统消息。

### Q3: 卖家输错交易码会怎样？

A: 系统会提示"交易验证码错误"，可以重新输入。没有尝试次数限制。

### Q4: 交易完成后还能修改评价吗？

A: 当前版本不支持修改评价。后续版本会增加该功能。

---

**文档版本**: v2.0
**最后更新**: 2025-10-01
**维护人**: 开发团队