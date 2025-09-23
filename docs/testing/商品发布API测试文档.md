# 📱 Fliliy 二手平台商品发布 API 测试文档

## 📋 文档信息

**文档版本**: v1.0  
**创建时间**: 2025-09-21  
**更新时间**: 2025-09-21  
**目标用户**: 前端开发者  
**测试状态**: ✅ 已验证通过

---

## 🔗 API 基本信息

### 接口地址
```
POST /api/v1/products
```

### 请求头
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer {JWT_ACCESS_TOKEN}"
}
```

### Base URL
- **开发环境**: `http://localhost:8080/api/v1`
- **测试环境**: `http://test-api.fliliy.com/api/v1`
- **生产环境**: `https://api.fliliy.com/api/v1`

---

## 📦 测试用例1: 最简化版本（推荐新手）

### 🎯 用途
- 快速功能验证
- 最小化出错风险
- 只包含必填字段
- 保修信息使用系统默认值

### 📄 JSON数据
```json
{
  "title": "iPhone 14 Pro 128GB",
  "price": 4999.00,
  "categoryId": 1,
  "images": ["https://example.com/iphone14.jpg"],
  "condition": "GOOD",
  "location": {
    "province": "北京市",
    "city": "北京市",
    "district": "朝阳区"
  }
}
```

### ✅ 预期响应
```json
{
  "code": 200,
  "message": "发布成功",
  "data": {
    "productId": "1234567890123456789",
    "status": "ACTIVE",
    "publishTime": "2025-09-21 22:00:00"
  },
  "timestamp": 1758463200000
}
```

### 🔍 字段说明
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | ✅ | 商品标题，最多200字 |
| price | number | ✅ | 商品价格，0.01-999999.99 |
| categoryId | integer | ✅ | 商品分类ID，1=电子产品 |
| images | array | ✅ | 图片URL数组，至少1张 |
| condition | string | ✅ | 商品状况枚举值 |
| location | object | ✅ | 位置信息对象 |

---

## 📦 测试用例2: 保修状况为 TRUE（完整版）

### 🎯 用途
- 测试有保修商品发布
- 验证所有可选字段
- 测试保修信息处理

### 📄 JSON数据
```json
{
  "title": "iPhone 15 Pro Max 256GB 钛金色",
  "description": "全新iPhone 15 Pro Max，个人自用，成色完美，配件齐全包装盒发票都在。因为要换安卓手机所以出售。",
  "price": 7999.00,
  "originalPrice": 9999.00,
  "categoryId": 1,
  "images": [
    "https://example.com/iphone15_front.jpg",
    "https://example.com/iphone15_back.jpg",
    "https://example.com/iphone15_box.jpg"
  ],
  "condition": "NEW",
  "usageInfo": {
    "type": "TIME",
    "value": 0,
    "unit": "MONTH"
  },
  "warranty": {
    "hasWarranty": true,
    "warrantyType": "OFFICIAL",
    "remainingMonths": 11,
    "description": "苹果官方保修，剩余11个月，支持全球联保"
  },
  "location": {
    "province": "广东省",
    "city": "深圳市",
    "district": "南山区",
    "detailAddress": "科技园南区",
    "longitude": 113.9465,
    "latitude": 22.5426
  },
  "tags": ["苹果", "手机", "全新", "未激活", "国行"]
}
```

### 🔍 保修字段说明
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| hasWarranty | boolean | ⚪ | 是否有保修 |
| warrantyType | string | ⚪ | 保修类型：OFFICIAL/STORE/NONE |
| remainingMonths | integer | ⚪ | 剩余保修月数，0-120 |
| description | string | ⚪ | 保修说明，最多200字 |

---

## 📦 测试用例3: 保修状况为 FALSE（完整版）

### 🎯 用途
- 测试无保修商品发布
- 验证保修状况切换
- 测试二手商品场景

### 📄 JSON数据
```json
{
  "title": "小米13 Ultra 12GB+256GB 黑色",
  "description": "小米13 Ultra徕卡影像旗舰，拍照效果一流。个人使用6个月，爱惜使用，功能完好无损坏。配件齐全：充电器、数据线、保护壳、钢化膜。因出国急售。",
  "price": 3299.00,
  "originalPrice": 5999.00,
  "categoryId": 1,
  "images": [
    "https://example.com/mi13ultra_1.jpg",
    "https://example.com/mi13ultra_2.jpg",
    "https://example.com/mi13ultra_3.jpg",
    "https://example.com/mi13ultra_accessories.jpg"
  ],
  "condition": "GOOD",
  "usageInfo": {
    "type": "TIME",
    "value": 6,
    "unit": "MONTH"
  },
  "warranty": {
    "hasWarranty": false,
    "warrantyType": "NONE",
    "remainingMonths": 0,
    "description": "已过保修期，但功能完好"
  },
  "location": {
    "province": "北京市",
    "city": "北京市",
    "district": "朝阳区",
    "detailAddress": "三里屯商圈",
    "longitude": 116.4551,
    "latitude": 39.9290
  },
  "tags": ["小米", "手机", "徕卡", "拍照神器", "二手"]
}
```

---

## 🔧 前端调用示例

### JavaScript Fetch API
```javascript
// 示例：发布商品
const publishProduct = async (productData) => {
  try {
    const response = await fetch('/api/v1/products', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
      },
      body: JSON.stringify(productData)
    });
    
    const result = await response.json();
    
    if (result.code === 200) {
      console.log('发布成功:', result.data);
      return result.data;
    } else {
      throw new Error(result.message);
    }
  } catch (error) {
    console.error('发布失败:', error);
    throw error;
  }
};

// 使用示例
publishProduct(simpleProductData)
  .then(data => {
    alert(`商品发布成功！商品ID: ${data.productId}`);
  })
  .catch(error => {
    alert(`发布失败: ${error.message}`);
  });
```

### jQuery AJAX
```javascript
$.ajax({
  url: '/api/v1/products',
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + localStorage.getItem('accessToken')
  },
  contentType: 'application/json',
  data: JSON.stringify(productData),
  success: function(response) {
    if (response.code === 200) {
      console.log('发布成功:', response.data);
    }
  },
  error: function(xhr, status, error) {
    console.error('发布失败:', error);
  }
});
```

### Axios
```javascript
const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
  }
});

// 发布商品
api.post('/products', productData)
  .then(response => {
    console.log('发布成功:', response.data);
  })
  .catch(error => {
    console.error('发布失败:', error.response.data);
  });
```

---

## 📏 字段完整规范

### ✅ 必填字段
| 字段 | 类型 | 限制 | 示例 |
|------|------|------|------|
| title | string | 1-200字符 | "iPhone 14 Pro 128GB" |
| price | number | 0.01-999999.99 | 4999.00 |
| categoryId | integer | >0 | 1 |
| images | array | 1-20个URL | ["https://..."] |
| condition | enum | 见枚举值 | "NEW" |
| location.province | string | 1-50字符 | "北京市" |
| location.city | string | 1-50字符 | "北京市" |
| location.district | string | 1-50字符 | "朝阳区" |

### ⚪ 可选字段
| 字段 | 类型 | 限制 | 默认值 |
|------|------|------|-------|
| description | string | 0-5000字符 | null |
| originalPrice | number | 0.01-999999.99 | null |
| usageInfo | object | 见子字段 | null |
| warranty | object | 见子字段 | 默认无保修 |
| location.detailAddress | string | 0-200字符 | null |
| location.longitude | number | -180到180 | null |
| location.latitude | number | -90到90 | null |
| tags | array | 0-10个标签 | [] |

### 📋 枚举值定义

#### 商品状况 (condition)
| 值 | 中文描述 | 英文描述 |
|----|----------|----------|
| NEW | 全新 | Brand new |
| LIKE_NEW | 几乎全新 | Like new |
| GOOD | 轻微使用痕迹 | Good condition |
| FAIR | 明显使用痕迹 | Fair condition |
| POOR | 需要维修 | Poor condition |

#### 保修类型 (warrantyType)
| 值 | 中文描述 |
|----|----------|
| OFFICIAL | 官方保修 |
| STORE | 店铺保修 |
| NONE | 无保修 |

#### 使用情况类型 (usageInfo.type)
| 值 | 中文描述 |
|----|----------|
| TIME | 按时间计算 |
| COUNT | 按次数计算 |

#### 时间单位 (usageInfo.unit)
| 值 | 中文描述 |
|----|----------|
| MONTH | 月 |
| YEAR | 年 |

---

## ⚠️ 常见错误及解决方案

### 1. 保修信息相关错误

#### ❌ 错误示例
```json
{
  "warranty": {
    "hasWarranty": false,
    "warrantyType": null  // ❌ 不能传null
  }
}
```

#### ✅ 正确示例
```json
{
  "warranty": {
    "hasWarranty": false,
    "warrantyType": "NONE"  // ✅ 明确指定
  }
}
```

#### 🎯 最佳实践
```json
{
  // ✅ 完全不传warranty字段，使用默认值
}
```

### 2. 常见验证错误

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| "商品标题不能为空" | title字段缺失 | 确保传入title字段 |
| "商品价格必须大于0" | price <= 0 | 设置price > 0.01 |
| "商品分类不能为空" | categoryId缺失 | 传入有效的categoryId |
| "商品图片不能为空" | images数组为空 | 至少传入一张图片URL |
| "保修类型只能是OFFICIAL、STORE或NONE" | warrantyType值错误 | 使用正确的枚举值 |

### 3. 图片上传流程

```javascript
// 1. 先上传图片获取URL
const uploadImage = async (file) => {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch('/api/v1/products/upload', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`
    },
    body: formData
  });
  
  const result = await response.json();
  return result.data.url;
};

// 2. 使用真实图片URL发布商品
const imageUrls = await Promise.all(files.map(uploadImage));
const productData = {
  ...otherFields,
  images: imageUrls
};
```

---

## 🚀 快速开始指南

### 1️⃣ 获取JWT Token
首先需要登录获取访问令牌：
```javascript
// 登录获取token
const loginResponse = await fetch('/api/v1/auth/login/password', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    mobile: "13800138000",
    password: "your_password"
  })
});
const { data } = await loginResponse.json();
const accessToken = data.accessToken;
```

### 2️⃣ 发布最简单的商品
```javascript
const simpleProduct = {
  "title": "测试商品",
  "price": 100.00,
  "categoryId": 1,
  "images": ["https://example.com/test.jpg"],
  "condition": "GOOD",
  "location": {
    "province": "北京市",
    "city": "北京市",
    "district": "朝阳区"
  }
};

// 发布
const result = await fetch('/api/v1/products', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`
  },
  body: JSON.stringify(simpleProduct)
});
```

### 3️⃣ 验证发布结果
成功发布后会返回商品ID，可以通过以下接口查看：
```javascript
// 查看商品详情
const productDetail = await fetch(`/api/v1/products/${productId}`);
```

---

## 📞 技术支持

如果在测试过程中遇到问题，请提供以下信息：

1. **请求数据**: 完整的JSON请求体
2. **响应结果**: 完整的响应数据
3. **错误信息**: 具体的错误提示
4. **测试环境**: 开发/测试/生产环境
5. **浏览器信息**: Chrome/Safari/Firefox版本

**联系方式**: 
- 技术群: 请在开发群中@后端开发
- 文档反馈: 请提交Issue或PR

---

## 📝 更新日志

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0 | 2025-09-21 | 初始版本，包含基础测试用例 |

---

**📌 提示**: 建议先使用"测试用例1"进行基础功能验证，确认无误后再测试完整版本。