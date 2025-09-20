# Fliliy 二手交易平台 API 接口文档 v2.1 [Production Ready]

## 📋 项目信息

**Base URL:** `http://localhost:8080/api/v1` (开发环境)  
**生产环境:** `https://api.fliliy.com/api/v1`  
**版本:** v2.0  
**认证方式:** Bearer Token (JWT)  
**数据库:** MySQL 8.0+

## 🔧 统一响应格式

```json
{
  "code": 200,
  "message": "success", 
  "data": {},
  "timestamp": 1640995200000
}
```

## 📊 状态码说明

| Code | 说明 |
|------|------|
| 200 | 成功 |
| 400 | 参数错误 |
| 401 | 未认证/token失效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 429 | 请求频率过高 |
| 500 | 服务器内部错误 |

---

# 1. 用户认证模块 [已实现]

## 1.1 系统健康检查

**接口:** `GET /health`

**响应示例:**
```json
{
  "code": 200,
  "message": "系统运行正常",
  "data": {
    "status": "UP",
    "timestamp": "2025-01-01T10:00:00",
    "version": "v2.0",
    "database": "connected"
  }
}
```

## 1.2 发送短信验证码

**接口:** `POST /auth/sms/send`

**请求参数:**
```json
{
  "mobile": "13800138000",  // 中国手机号：13-19开头11位
  "type": "register"     // register注册, login登录, reset重置密码
}
```

**澳洲手机号示例:**
```json
{
  "mobile": "0412345678",   // 澳洲手机号：04或05开头10位
  "type": "register"
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "验证码发送成功",
  "data": {
    "smsId": "sms_1640995200000",
    "expireTime": 300
  }
}
```

**手机号格式支持:**
- **中国手机号:** 13-19开头的11位数字（如：13800138000）
- **澳洲手机号:** 04或05开头的10位数字（如：0412345678）

**业务规则:**
- **验证码为4位数字** ✅ 已测试验证
- 同一手机号60秒内只能发送一次 ✅ 已实现
- 验证码有效期5分钟 ✅ 已实现
- 每日每手机号最多发送10次 ✅ 已实现
- 测试环境验证码在控制台日志中显示 ✅ 已验证

## 1.3 用户注册

**接口:** `POST /auth/register`

**请求参数:**
```json
{
  "username": "张三",
  "mobile": "13800138000",       // 支持中国(13-19开头11位)和澳洲(04-05开头10位)手机号
  "password": "password123",
  "confirmPassword": "password123",
  "smsCode": "1234",              // 4位验证码 ✅ 已验证
  "smsId": "sms_1640995200000",
  "agreeTerms": true
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": "1640995200000001",
    "username": "张三",
    "mobile": "13800138000",
    "avatar": "https://cdn.fliliy.com/avatar/default.png",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 7200
  }
}
```

## 1.4 密码登录

**接口:** `POST /auth/login/password`

**请求参数:**
```json
{
  "mobile": "13800138000",      // 支持中国(13-19开头11位)和澳洲(04-05开头10位)手机号
  "password": "password123",
  "rememberMe": true
}
```

## 1.5 验证码登录

**接口:** `POST /auth/login/sms`

**请求参数:**
```json
{
  "mobile": "13800138000",      // 支持中国(13-19开头11位)和澳洲(04-05开头10位)手机号
  "smsCode": "1234",              // 4位验证码 ✅ 已验证
  "smsId": "sms_1640995200000"
}
```

## 1.6 刷新Token

**接口:** `POST /auth/token/refresh`

**请求参数:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## 1.7 退出登录

**接口:** `POST /auth/logout`

**请求参数:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

# 2. 商品管理模块 [新增模块]

## 2.1 获取商品分类

**接口:** `GET /categories`

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "name": "电子产品",
      "icon": "https://cdn.fliliy.com/icons/electronics.png",
      "parentId": 0,
      "sortOrder": 1,
      "isActive": true,
      "children": [
        {
          "id": 11,
          "name": "手机",
          "icon": "https://cdn.fliliy.com/icons/mobile.png",
          "parentId": 1,
          "sortOrder": 1,
          "isActive": true
        },
        {
          "id": 12,
          "name": "电脑",
          "parentId": 1,
          "sortOrder": 2,
          "isActive": true
        }
      ]
    }
  ]
}
```

## 2.2 上传商品图片

**接口:** `POST /products/upload`

**请求头:** 
- `Authorization: Bearer {accessToken}`
- `Content-Type: multipart/form-data`

**请求参数:**
- `file`: 图片文件（单次上传，最多20张图片）

**响应示例:**
```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "url": "http://localhost:8080/api/v1/files/products/1640995200000_1.jpg",
    "filename": "1640995200000_1.jpg",
    "size": 1024000,
    "uploadTime": "2025-01-01T10:00:00"
  }
}
```

**业务规则:**
- 支持格式：jpg, jpeg, png, webp
- 单个文件最大10MB
- 单个商品最多20张图片
- 本地存储在`/api/v1/files/products/`目录
- 第一张图片默认为主图

## 2.3 发布商品

**接口:** `POST /products`

**请求头:** `Authorization: Bearer {accessToken}`

**请求参数:**
```json
{
  "title": "iPhone 12 Pro Max 128GB",
  "description": "个人自用，95新无磕碰，功能完好，配件齐全，有发票",
  "price": 5999.00,
  "originalPrice": 6999.00,      // 可选，原价用于显示折扣
  "categoryId": 11,
  "images": [
    "http://localhost:8080/api/v1/files/products/1640995200000_1.jpg",
    "http://localhost:8080/api/v1/files/products/1640995200000_2.jpg"
  ],
  "condition": "LIKE_NEW",        // 商品状况
  "usageInfo": {
    "type": "TIME",               // TIME时间 或 COUNT次数（用户选择）
    "value": 6,
    "unit": "MONTH"               // MONTH月 或 YEAR年
  },
  "warranty": {
    "hasWarranty": true,          // 是否有保修
    "warrantyType": "OFFICIAL",   // OFFICIAL官方, STORE店铺, NONE无保修
    "remainingMonths": 10,        // 剩余保修月数
    "description": "苹果官方保修"
  },
  "location": {
    "province": "北京市",
    "city": "北京市", 
    "district": "朝阳区",
    "detailAddress": "三里屯",    // 大致位置，不显示详细地址
    "longitude": 116.404,        // 经纬度（用于附近搜索）
    "latitude": 39.915
  },
  "tags": ["个人自用", "配件齐全", "有发票"]  // 可选标签
}
```

**商品状况枚举:**
- `NEW` - 全新
- `LIKE_NEW` - 几乎全新
- `GOOD` - 轻微使用痕迹
- `FAIR` - 明显使用痕迹  
- `POOR` - 需要维修

**响应示例:**
```json
{
  "code": 200,
  "message": "发布成功",
  "data": {
    "productId": "1640995200000001",
    "status": "ACTIVE",
    "publishTime": "2025-01-01T10:00:00"
  }
}
```

## 2.4 获取商品列表（主页）

**接口:** `GET /products`

**查询参数:**
```
page: 1                    // 页码，从1开始
size: 4                    // 每页数量，默认4（瀑布流）
category: 11               // 分类ID（可选）
keyword: iPhone            // 搜索关键词（商品标题模糊搜索）
filter: popular            // 筛选：all全部, popular流行, discount打折, brand品牌, accessories配件
                           // - all: 显示所有商品
                           // - popular: 显示热门商品（基于浏览量、收藏量等）
                           // - discount: 显示有折扣的商品（有originalPrice且低于原价）
                           // - brand: 显示品牌商品（知名品牌标识）
                           // - accessories: 显示配件类商品
sort: time_desc            // 排序：time_desc最新, price_asc价格升序, price_desc价格降序
minPrice: 1000             // 最低价格（可选）
maxPrice: 10000            // 最高价格（可选）
condition: LIKE_NEW        // 商品状况筛选（可选）
hasWarranty: true          // 是否有保修（可选）
longitude: 116.404         // 经度（用于附近搜索，可选）
latitude: 39.915           // 纬度（用于附近搜索，可选）
radius: 500                // 搜索半径，单位米（默认500米）
```

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "products": [
      {
        "id": "1640995200000001",
        "title": "iPhone 12 Pro Max 128GB",
        "price": 5999.00,
        "originalPrice": 6999.00,
        "discount": "85折",
        "mainImage": "http://localhost:8080/api/v1/files/products/1640995200000_1.jpg",
        "condition": "LIKE_NEW",
        "conditionText": "几乎全新",
        "location": "北京市朝阳区",
        "distance": "1.2km",           // 距离（如果有定位）
        "publishTime": "2025-01-01T10:00:00",
        "hasWarranty": true,
        "warrantyText": "保修10个月",
        "seller": {
          "id": "1640995200000002",
          "username": "张三",
          "avatar": "https://cdn.fliliy.com/avatar/user.jpg",
          "verified": true,
          "rating": 4.8
        },
        "stats": {
          "viewCount": 120,
          "favoriteCount": 15,
          "chatCount": 5,
          "isOwn": false,            // 是否是当前用户发布的
          "isFavorited": false       // 是否已收藏
        },
        "tags": ["个人自用", "配件齐全"]
      }
    ],
    "pagination": {
      "page": 1,
      "size": 4,
      "total": 100,
      "totalPages": 25,
      "hasNext": true
    },
    "filters": {                     // 当前筛选条件汇总
      "filter": "popular",           // 当前筛选类型
      "filterText": "热门商品",      // 筛选类型显示文本
      "category": "手机",
      "priceRange": "1000-10000",
      "condition": "几乎全新", 
      "location": "北京市朝阳区"
    }
  }
}
```

### 筛选功能使用示例

**获取热门商品：**
```
GET /products?filter=popular&page=1&size=10
```

**获取打折商品：**
```
GET /products?filter=discount&category=11&minPrice=1000&maxPrice=5000
```

**获取品牌商品：**
```
GET /products?filter=brand&keyword=iPhone&sort=price_asc
```

**获取配件类商品：**
```
GET /products?filter=accessories&location=北京&radius=1000
```

**综合筛选示例：**
```
GET /products?filter=popular&category=11&condition=LIKE_NEW&hasWarranty=true&minPrice=2000&maxPrice=8000&sort=time_desc&page=1&size=4
```

### 筛选逻辑说明

| 筛选类型 | 筛选逻辑 | 备注 |
|---------|---------|------|
| `all` | 不应用特殊筛选，显示所有符合其他条件的商品 | 默认值 |
| `popular` | 根据综合热度排序（浏览量×0.4 + 收藏量×0.3 + 聊天量×0.3） | 近7天数据加权 |
| `discount` | 仅显示有原价且当前价格低于原价的商品 | 必须有originalPrice字段且price < originalPrice |
| `brand` | 显示标记为知名品牌的商品 | 基于商品标题关键词匹配或商品标签 |
| `accessories` | 显示配件类商品 | 基于分类ID或标题关键词识别 |

**注意事项：**
- 筛选参数可与其他查询参数组合使用
- 筛选结果仍受分页参数控制  
- 排序参数会影响筛选结果的展示顺序
- 地理位置筛选仅在提供经纬度时生效

## 2.5 获取商品详情

**接口:** `GET /products/{productId}`

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "1640995200000001",
    "title": "iPhone 12 Pro Max 128GB",
    "description": "个人自用，95新无磕碰，功能完好，配件齐全，有发票。\n\n购买于2023年3月，一直贴膜使用，外观完好。\n配件包括：原装充电器、数据线、耳机、包装盒、发票。\n\n非诚勿扰，可小刀，支持当面验货。",
    "price": 5999.00,
    "originalPrice": 6999.00,
    "discount": "85折",
    "categoryId": 11,
    "categoryName": "手机",
    "categoryPath": "电子产品 > 手机",
    "images": [
      "http://localhost:8080/api/v1/files/products/1640995200000_1.jpg",
      "http://localhost:8080/api/v1/files/products/1640995200000_2.jpg",
      "http://localhost:8080/api/v1/files/products/1640995200000_3.jpg"
    ],
    "condition": "LIKE_NEW",
    "conditionText": "几乎全新",
    "usageInfo": {
      "type": "TIME",
      "value": 6,
      "unit": "MONTH",
      "displayText": "使用6个月"
    },
    "warranty": {
      "hasWarranty": true,
      "warrantyType": "OFFICIAL",
      "remainingMonths": 10,
      "description": "苹果官方保修",
      "displayText": "苹果官方保修，剩余10个月"
    },
    "location": {
      "province": "北京市",
      "city": "北京市",
      "district": "朝阳区",
      "detailAddress": "三里屯",
      "displayText": "北京市朝阳区三里屯",
      "distance": "1.2km"
    },
    "seller": {
      "id": "1640995200000002",
      "username": "张三",
      "avatar": "https://cdn.fliliy.com/avatar/user.jpg",
      "verified": true,
      "registeredDays": 365,
      "totalProducts": 25,
      "soldCount": 18,
      "rating": 4.8,
      "reviewCount": 32,
      "responseRate": "95%",
      "avgResponseTime": "30分钟内"
    },
    "stats": {
      "viewCount": 120,
      "favoriteCount": 15,
      "chatCount": 5,
      "isOwn": false,
      "isFavorited": false
    },
    "publishTime": "2025-01-01T10:00:00",
    "updatedTime": "2025-01-01T12:00:00",
    "status": "ACTIVE",
    "tags": ["个人自用", "配件齐全", "有发票"],
    "relatedProducts": [              // 相关推荐商品（可选）
      {
        "id": "1640995200000002", 
        "title": "iPhone 12 Pro 256GB",
        "price": 5299.00,
        "mainImage": "http://localhost:8080/api/v1/files/products/1640995200000_4.jpg"
      }
    ]
  }
}
```

## 2.6 收藏/取消收藏商品

**接口:** `POST /products/{productId}/favorite`

**请求头:** `Authorization: Bearer {accessToken}`

**响应示例:**
```json
{
  "code": 200,
  "message": "收藏成功",
  "data": {
    "isFavorited": true,
    "favoriteCount": 16
  }
}
```

## 2.7 编辑商品

**接口:** `PUT /products/{productId}`

**请求头:** `Authorization: Bearer {accessToken}`

**请求参数:** 同发布商品，只能编辑自己发布的商品

## 2.8 删除商品（下架）

**接口:** `DELETE /products/{productId}`

**请求头:** `Authorization: Bearer {accessToken}`

**响应示例:**
```json
{
  "code": 200,
  "message": "商品已下架",
  "data": {
    "productId": "1640995200000001",
    "status": "INACTIVE"
  }
}
```

---

# 3. 交易管理模块 [新增模块]

## 3.1 发起咨询/交易意向

**接口:** `POST /transactions/inquiry`

**请求头:** `Authorization: Bearer {accessToken}`

**请求参数:**
```json
{
  "productId": "1640995200000001",
  "sellerId": "1640995200000002",
  "message": "你好，这个商品还在吗？可以优惠吗？",
  "inquiryType": "PURCHASE"          // PURCHASE购买咨询, INFO信息咨询
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "咨询发起成功",
  "data": {
    "transactionId": "tx_1640995200000001",
    "chatRoomId": "chat_1640995200000001",
    "status": "INQUIRY"
  }
}
```

## 3.2 同意线下交易

**接口:** `POST /transactions/{transactionId}/agree-offline`

**请求头:** `Authorization: Bearer {accessToken}`

**请求参数:**
```json
{
  "message": "好的，明天下午3点三里屯见面交易",
  "meetingTime": "2025-01-02T15:00:00",
  "contactInfo": {
    "contactName": "张三",
    "contactPhone": "13800138000"
  },
  "meetingLocation": {
    "locationName": "三里屯太古里",
    "detailAddress": "南区1号楼星巴克门口",
    "longitude": 116.404,
    "latitude": 39.915
  },
  "notes": "请带好商品和充电器，到时微信联系"
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "线下交易确认成功",
  "data": {
    "transactionCode": "1234",        // 4位交易验证码
    "expiresAt": "2025-01-02T15:00:00",
    "meetingInfo": {
      "meetingTime": "2025-01-02T15:00:00",
      "locationName": "三里屯太古里",
      "contactName": "张三",
      "contactPhone": "138****8000"   // 脱敏显示
    }
  }
}
```

**业务规则:**
- 双方都同意后生成4位数字验证码
- 验证码有效期24小时
- 卖家需要买家的验证码来确认交易完成

## 3.3 确认交易完成

**接口:** `POST /transactions/{transactionId}/complete`

**请求头:** `Authorization: Bearer {accessToken}`

**请求参数:**
```json
{
  "transactionCode": "1234",         // 买家提供给卖家的验证码
  "feedback": "交易顺利，买家很好沟通",  // 可选评价
  "rating": 5                        // 1-5星评分
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "交易确认成功",
  "data": {
    "transactionId": "tx_1640995200000001",
    "status": "COMPLETED",
    "completedAt": "2025-01-01T15:30:00",
    "productStatus": "SOLD"           // 商品状态更新为已售出
  }
}
```

## 3.4 取消交易

**接口:** `POST /transactions/{transactionId}/cancel`

**请求参数:**
```json
{
  "reason": "买家不需要了",
  "cancelType": "BUYER_CANCEL"       // BUYER_CANCEL买家取消, SELLER_CANCEL卖家取消
}
```

## 3.5 获取交易记录

**接口:** `GET /transactions`

**请求头:** `Authorization: Bearer {accessToken}`

**查询参数:**
```
type: buy         // buy买入记录, sell卖出记录, all全部
status: all       // INQUIRY咨询中, AGREED已同意, COMPLETED已完成, CANCELLED已取消
page: 1
size: 10
```

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功", 
  "data": {
    "transactions": [
      {
        "id": "tx_1640995200000001",
        "type": "BUY",
        "status": "COMPLETED",
        "statusText": "交易完成",
        "product": {
          "id": "1640995200000001",
          "title": "iPhone 12 Pro Max",
          "price": 5999.00,
          "mainImage": "http://localhost:8080/api/v1/files/products/img1.jpg"
        },
        "counterpart": {              // 交易对方
          "id": "1640995200000002",
          "username": "张三",
          "avatar": "https://cdn.fliliy.com/avatar/user.jpg"
        },
        "transactionTime": "2025-01-01T15:30:00",
        "meetingInfo": {
          "meetingTime": "2025-01-02T15:00:00",
          "locationName": "三里屯太古里"
        },
        "canRate": false,             // 是否可以评价
        "rating": 5                   // 已评分
      }
    ],
    "pagination": {
      "page": 1,
      "size": 10,
      "total": 25,
      "hasNext": true
    }
  }
}
```

---

# 4. 聊天系统模块 [新增模块]

## 4.1 获取聊天列表

**接口:** `GET /chats`

**请求头:** `Authorization: Bearer {accessToken}`

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "chatRoomId": "chat_1640995200000001",
      "transactionId": "tx_1640995200000001",
      "product": {
        "id": "1640995200000001",
        "title": "iPhone 12 Pro Max",
        "price": 5999.00,
        "mainImage": "http://localhost:8080/api/v1/files/products/img1.jpg",
        "status": "ACTIVE"
      },
      "participant": {                // 聊天对方
        "id": "1640995200000002",
        "username": "李四",
        "avatar": "https://cdn.fliliy.com/avatar/user2.jpg",
        "isOnline": true,
        "lastSeenAt": "2025-01-01T14:30:00"
      },
      "lastMessage": {
        "id": "msg_1640995200000005",
        "content": "好的，明天下午见面交易",
        "type": "TEXT",
        "sentAt": "2025-01-01T14:30:00",
        "senderName": "李四",
        "isFromMe": false
      },
      "unreadCount": 2,
      "totalMessages": 15,
      "createdAt": "2025-01-01T10:00:00",
      "updatedAt": "2025-01-01T14:30:00",
      "transactionStatus": "AGREED"     // 对应交易状态
    }
  ]
}
```

## 4.2 获取聊天记录

**接口:** `GET /chats/{chatRoomId}/messages`

**请求头:** `Authorization: Bearer {accessToken}`

**查询参数:**
```
page: 1
size: 20
before: 1640995200000    // 获取指定时间戳之前的消息（时间倒序分页）
```

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "chatInfo": {
      "chatRoomId": "chat_1640995200000001",
      "product": {
        "id": "1640995200000001",
        "title": "iPhone 12 Pro Max",
        "mainImage": "http://localhost:8080/api/v1/files/products/img1.jpg",
        "status": "ACTIVE",
        "price": 5999.00
      },
      "participant": {
        "id": "1640995200000002",
        "username": "李四",
        "avatar": "https://cdn.fliliy.com/avatar/user2.jpg",
        "isOnline": true
      }
    },
    "messages": [
      {
        "id": "msg_1640995200000001",
        "senderId": "1640995200000001",
        "senderName": "张三",
        "type": "TEXT",
        "content": "你好，这个商品还在吗？",
        "sentAt": "2025-01-01T10:00:00",
        "isFromMe": true,
        "status": "READ"                // SENT已发送, DELIVERED已送达, READ已读
      },
      {
        "id": "msg_1640995200000002",
        "senderId": "1640995200000002",
        "senderName": "李四",
        "type": "IMAGE",
        "content": "http://localhost:8080/api/v1/files/chat/img1.jpg",
        "thumbnail": "http://localhost:8080/api/v1/files/chat/thumb_img1.jpg",
        "imageSize": {
          "width": 800,
          "height": 600
        },
        "sentAt": "2025-01-01T10:05:00",
        "isFromMe": false,
        "status": "READ"
      },
      {
        "id": "msg_1640995200000003", 
        "senderId": "1640995200000002",
        "senderName": "李四",
        "type": "VOICE",
        "content": "http://localhost:8080/api/v1/files/chat/voice1.aac",
        "duration": 15,                  // 语音时长（秒）
        "waveform": "data:audio/wav;base64,...",  // 语音波形数据（可选）
        "sentAt": "2025-01-01T10:10:00",
        "isFromMe": false,
        "status": "DELIVERED"
      },
      {
        "id": "msg_1640995200000004",
        "senderId": "1640995200000001",
        "senderName": "张三",
        "type": "SYSTEM",
        "content": "双方已同意线下交易，交易码：1234",
        "sentAt": "2025-01-01T14:00:00",
        "isFromMe": false,
        "status": "SYSTEM",
        "systemData": {                  // 系统消息附加数据
          "transactionCode": "1234",
          "meetingTime": "2025-01-02T15:00:00",
          "location": "三里屯太古里"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "hasMore": true,
      "oldestTimestamp": 1640995100000
    }
  }
}
```

## 4.3 发送消息

**接口:** `POST /chats/{chatRoomId}/messages`

**请求头:** `Authorization: Bearer {accessToken}`

### 4.3.1 发送文本消息

**请求参数:**
```json
{
  "type": "TEXT",
  "content": "好的，我们明天下午3点见面交易，地点在三里屯太古里"
}
```

### 4.3.2 发送图片消息

**请求参数:**
```json
{
  "type": "IMAGE", 
  "content": "http://localhost:8080/api/v1/files/chat/img1.jpg",
  "thumbnail": "http://localhost:8080/api/v1/files/chat/thumb_img1.jpg"
}
```

### 4.3.3 发送语音消息

**请求参数:**
```json
{
  "type": "VOICE",
  "content": "http://localhost:8080/api/v1/files/chat/voice1.aac",
  "duration": 15
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "发送成功",
  "data": {
    "messageId": "msg_1640995200000005",
    "sentAt": "2025-01-01T14:35:00",
    "status": "SENT"
  }
}
```

## 4.4 上传聊天文件

**接口:** `POST /chats/upload`

**请求头:** 
- `Authorization: Bearer {accessToken}`
- `Content-Type: multipart/form-data`

**请求参数:**
- `file`: 文件（图片/语音）
- `type`: 文件类型（image/voice）

**响应示例:**
```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "url": "http://localhost:8080/api/v1/files/chat/img1.jpg",
    "thumbnail": "http://localhost:8080/api/v1/files/chat/thumb_img1.jpg",  // 图片才有
    "filename": "img1.jpg",
    "size": 1024000,
    "duration": 15                     // 语音才有
  }
}
```

**业务规则:**
- 图片格式：jpg, jpeg, png, webp
- 语音格式：aac, mp3, wav
- 语音最长60秒
- 图片自动生成缩略图

## 4.5 标记消息已读

**接口:** `POST /chats/{chatRoomId}/read`

**请求参数:**
```json
{
  "lastReadMessageId": "msg_1640995200000005"
}
```

---

# 5. 用户中心模块 [扩展现有功能]

## 5.1 获取用户信息

**接口:** `GET /user/profile`

**请求头:** `Authorization: Bearer {accessToken}`

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "1640995200000001",
    "username": "张三",
    "mobile": "138****8000",           // 脱敏显示
    "email": "zhang***@example.com",  // 脱敏显示
    "avatar": "https://cdn.fliliy.com/avatar/user.jpg",
    "gender": 1,                      // 0未知, 1男, 2女
    "birthday": "1990-01-01",
    "location": "北京市朝阳区",
    "bio": "闲置物品转让，诚信交易",
    "verified": true,
    "registeredAt": "2023-01-01T00:00:00",
    "lastLoginAt": "2025-01-01T08:00:00",
    "stats": {
      "publishedCount": 25,           // 发布商品数
      "activeCount": 18,              // 在售商品数
      "soldCount": 15,                // 已售出数
      "boughtCount": 8,               // 购买数
      "favoriteCount": 32,            // 收藏数
      "chatCount": 12,                // 聊天数
      "points": 0,                    // 积分（预留）
      "credits": 100                  // 信用分（预留）
    },
    "rating": {
      "average": 4.8,
      "total": 20,
      "distribution": {               // 评分分布
        "5": 15,
        "4": 3,
        "3": 2,
        "2": 0,
        "1": 0
      }
    },
    "preferences": {                  // 用户偏好设置
      "pushNotification": true,
      "emailNotification": false,
      "showMobile": false,
      "showLocation": true
    }
  }
}
```

## 5.2 更新用户信息

**接口:** `PUT /user/profile`

**请求参数:**
```json
{
  "username": "新昵称",
  "avatar": "https://cdn.fliliy.com/avatar/new.jpg",
  "gender": 1,
  "birthday": "1990-01-01",
  "location": "上海市浦东新区",
  "bio": "专业二手数码设备交易",
  "email": "new@example.com"
}
```

## 5.3 获取我的商品

**接口:** `GET /user/products`

**查询参数:**
```
status: active    // active在售, sold已售, inactive下架, all全部
page: 1
size: 10
sort: time_desc   // time_desc最新, time_asc最早, price_desc价格高到低, view_desc浏览最多
```

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "products": [
      {
        "id": "1640995200000001",
        "title": "iPhone 12 Pro Max",
        "price": 5999.00,
        "mainImage": "http://localhost:8080/api/v1/files/products/img1.jpg",
        "status": "ACTIVE",
        "statusText": "在售中",
        "publishTime": "2025-01-01T10:00:00",
        "stats": {
          "viewCount": 120,
          "favoriteCount": 15,
          "chatCount": 5,
          "inquiryCount": 8           // 咨询数量
        },
        "actions": [                  // 可执行的操作
          "EDIT", "DELETE", "PROMOTE", "VIEW_CHATS"
        ]
      }
    ],
    "summary": {                     // 商品统计
      "total": 25,
      "active": 18,
      "sold": 5,
      "inactive": 2
    },
    "pagination": {
      "page": 1,
      "size": 10,
      "total": 25,
      "hasNext": true
    }
  }
}
```

## 5.4 获取我的收藏

**接口:** `GET /user/favorites`

**查询参数:**
```
status: active    // active在售, sold已售, inactive下架, all全部
page: 1
size: 10
sort: time_desc   // time_desc收藏时间, price_asc价格升序, price_desc价格降序
```

## 5.5 获取收货地址

**接口:** `GET /user/addresses`

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": "addr_1640995200000001",
      "contactName": "张三",
      "contactPhone": "13800138000",
      "province": "北京市",
      "city": "北京市",
      "district": "朝阳区",
      "detailAddress": "三里屯太古里1号楼101室",
      "fullAddress": "北京市朝阳区三里屯太古里1号楼101室",
      "longitude": 116.404,
      "latitude": 39.915,
      "isDefault": true,
      "usageCount": 5,                // 使用次数
      "createdAt": "2024-01-01T00:00:00",
      "lastUsedAt": "2024-01-01T10:00:00"
    }
  ]
}
```

## 5.6 添加收货地址

**接口:** `POST /user/addresses`

**请求参数:**
```json
{
  "contactName": "张三",
  "contactPhone": "13800138000", 
  "province": "北京市",
  "city": "北京市",
  "district": "朝阳区",
  "detailAddress": "三里屯太古里1号楼101室",
  "longitude": 116.404,            // 可选，用于定位
  "latitude": 39.915,              // 可选，用于定位
  "isDefault": false
}
```

## 5.7 设置默认地址

**接口:** `PUT /user/addresses/{addressId}/default`

## 5.8 获取消息通知

**接口:** `GET /user/notifications`

**查询参数:**
```
type: all         // system系统通知, chat聊天消息, transaction交易通知, all全部
status: unread    // read已读, unread未读, all全部
page: 1
size: 20
```

---

# 6. 文件管理模块 [新增模块]

## 6.1 获取上传文件

**接口:** `GET /files/{category}/{filename}`

**参数说明:**
- `category`: 文件分类（products商品图片, chat聊天文件, avatar头像）
- `filename`: 文件名

**示例:** `GET /files/products/1640995200000_1.jpg`

**业务规则:**
- 本地文件存储在`src/main/resources/static/files/`目录
- 支持图片格式预览
- 大图片自动压缩
- 生成缩略图（thumbnail前缀）

---

# 7. 系统配置模块 [扩展]

## 7.1 获取系统配置

**接口:** `GET /system/config`

**响应示例:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "version": "v2.0",
    "upload": {
      "maxImageCount": 20,
      "maxImageSize": "10MB",
      "maxVoiceDuration": 60,
      "supportedImageFormats": ["jpg", "jpeg", "png", "webp"],
      "supportedVoiceFormats": ["aac", "mp3", "wav"]
    },
    "sms": {
      "codeLength": 4,                // 验证码位数
      "expireMinutes": 5,             // 有效期分钟
      "dailyLimit": 10                // 每日限制
    },
    "transaction": {
      "codeLength": 4,                // 交易码位数
      "expireHours": 24               // 有效期小时
    },
    "features": {
      "locationService": false,       // 定位服务（当前关闭）
      "aiEvaluation": false,          // AI评估（当前关闭）
      "onlinePayment": false,         // 在线支付（当前关闭）
      "pushNotification": true
    }
  }
}
```

---

# 错误码说明

## 用户认证相关（1xxx）

| Code | Message |
|------|---------|
| 1001 | 手机号格式错误（支持中国13-19开头11位和澳洲04-05开头10位） |
| 1002 | 密码格式错误 |
| 1003 | 验证码错误 |
| 1004 | 验证码已过期 |
| 1005 | 验证码发送过于频繁 |
| 1006 | 用户已存在 |
| 1007 | 用户不存在 |
| 1008 | 密码错误 |
| 1009 | 账号已锁定 |
| 1010 | Token已过期 |
| 1011 | Token无效 |
| 1012 | 权限不足 |

## 商品相关（2xxx）

| Code | Message |
|------|---------|
| 2001 | 商品不存在 |
| 2002 | 商品已下架 |
| 2003 | 非商品所有者 |
| 2004 | 图片上传失败 |
| 2005 | 图片数量超限 |
| 2006 | 分类不存在 |
| 2007 | 商品标题不能为空 |
| 2008 | 价格必须大于0 |
| 2009 | 商品描述过长 |
| 2010 | 商品已被收藏 |
| 2011 | 商品未被收藏 |

## 交易相关（3xxx）

| Code | Message |
|------|---------|
| 3001 | 交易不存在 |
| 3002 | 交易验证码错误 |
| 3003 | 交易验证码已过期 |
| 3004 | 无权限操作此交易 |
| 3005 | 不能与自己交易 |
| 3006 | 交易状态不正确 |
| 3007 | 商品不可交易 |
| 3008 | 交易已取消 |
| 3009 | 交易已完成 |

## 聊天相关（4xxx）

| Code | Message |
|------|---------|
| 4001 | 聊天室不存在 |
| 4002 | 无权限访问聊天室 |
| 4003 | 消息发送失败 |
| 4004 | 文件上传失败 |
| 4005 | 语音时长超限 |
| 4006 | 文件格式不支持 |
| 4007 | 文件大小超限 |
| 4008 | 消息内容不能为空 |

## 用户相关（5xxx）

| Code | Message |
|------|---------|
| 5001 | 用户名已存在 |
| 5002 | 用户名格式错误 |
| 5003 | 地址不存在 |
| 5004 | 默认地址不能删除 |
| 5005 | 头像上传失败 |
| 5006 | 用户信息更新失败 |

## 系统相关（9xxx）

| Code | Message |
|------|---------|
| 9001 | 系统维护中 |
| 9002 | 服务暂不可用 |
| 9003 | 请求频率过高 |
| 9004 | 参数验证失败 |
| 9005 | 数据库连接失败 |

---

# 开发指南

## 接口测试

### 本地环境
```bash
# 启动项目
mvn spring-boot:run

# 健康检查
curl http://localhost:8080/api/v1/health

# 查看H2数据库（开发环境）
# 访问：http://localhost:8080/h2-console
# JDBC URL: jdbc:h2:mem:testdb
# User: sa
# Password: (空)
```

### 认证流程测试
```bash
# 1. 发送验证码
curl -X POST http://localhost:8080/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"mobile": "13800138000", "type": "register"}'

# 2. 注册用户（使用控制台显示的验证码）
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "测试用户",
    "mobile": "13800138000", 
    "password": "password123",
    "confirmPassword": "password123",
    "smsCode": "1234",
    "smsId": "从上一步获取",
    "agreeTerms": true
  }'

# 3. 登录（获取token）
curl -X POST http://localhost:8080/api/v1/auth/login/password \
  -H "Content-Type: application/json" \
  -d '{
    "mobile": "13800138000",
    "password": "password123"
  }'
```

## 数据库配置

### 开发环境（H2内存数据库）
```properties
# application.properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.jpa.hibernate.ddl-auto=create-drop
```

### 生产环境（MySQL）
```properties
# application-prod.properties
spring.datasource.url=jdbc:mysql://localhost:3306/fliliy_db
spring.datasource.username=root
spring.datasource.password=your_password
spring.jpa.hibernate.ddl-auto=update
```

## 部署说明

1. **构建项目**
```bash
mvn clean package -DskipTests
```

2. **运行JAR**
```bash
java -jar -Dspring.profiles.active=prod target/second-hand-0.0.1-SNAPSHOT.jar
```

3. **Docker部署**（可选）
```dockerfile
FROM openjdk:8-jre-alpine
COPY target/second-hand-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app.jar"]
```

---

**文档版本:** v2.0  
**最后更新:** 2025-01-01  
**开发状态:** 认证模块已完成，商品/交易/聊天模块设计完成  
**下一步:** 实现商品管理模块