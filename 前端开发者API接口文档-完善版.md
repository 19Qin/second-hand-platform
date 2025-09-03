# 🚀 Fliliy 二手交易平台 API 接口文档 [前端开发者版本]

## 📖 文档说明

**版本**: v2.2 [前端开发者专用版]  
**更新时间**: 2025-09-02  
**目标用户**: 前端开发人员  
**文档特点**: 注重实用性，包含完整示例和错误处理

---

## 🎯 前端开发者快速上手指南

### 1. **30秒快速了解**

这是一个**RESTful API**，所有接口都返回**统一的JSON格式**：

```json
{
  "code": 200,
  "message": "操作成功",
  "data": { /* 具体数据 */ },
  "timestamp": 1640995200000
}
```

### 2. **5分钟开始开发**

```javascript
// 基础配置
const API_BASE_URL = 'http://localhost:8080/api/v1';

// 统一请求封装
const apiRequest = async (url, options = {}) => {
  const token = localStorage.getItem('accessToken');
  
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...(token && { 'Authorization': `Bearer ${token}` })
    },
    ...options
  };
  
  const response = await fetch(`${API_BASE_URL}${url}`, config);
  const result = await response.json();
  
  // 统一错误处理
  if (result.code !== 200) {
    throw new Error(result.message);
  }
  
  return result.data;
};
```

### 3. **认证流程（必读）**

```
用户打开APP → 检查本地Token → 
├─ 有Token: 调用/auth/validate验证 → 有效则直接进入主页
└─ 无Token: 显示登录页面 → 登录成功后保存Token
```

---

## 🏗️ 接口架构说明

### **Base URL**
- **开发环境**: `http://localhost:8080/api/v1`
- **测试环境**: `http://test-api.fliliy.com/api/v1`
- **生产环境**: `https://api.fliliy.com/api/v1`

### **认证方式**
```
Authorization: Bearer {accessToken}
```

### **统一响应格式**

#### ✅ 成功响应
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    // 具体业务数据
  },
  "timestamp": 1640995200000
}
```

#### ❌ 错误响应
```json
{
  "code": 1001,
  "message": "手机号格式错误",
  "data": null,
  "timestamp": 1640995200000
}
```

#### 🔧 开发环境响应（额外debug信息）
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { /* 业务数据 */ },
  "timestamp": 1640995200000,
  "debug": {
    "requestId": "req_1640995200000",
    "executionTime": 235,
    "sqlCount": 3,
    "cacheHit": true
  }
}
```

---

## 📊 状态码说明（前端必知）

| Code范围 | 类型 | 说明 | 前端处理建议 |
|---------|------|------|-------------|
| **200** | 成功 | 操作成功 | 正常处理数据 |
| **400** | 客户端错误 | 参数错误 | 提示用户重新输入 |
| **401** | 认证错误 | Token无效/过期 | **跳转到登录页** |
| **403** | 权限错误 | 无权限访问 | 提示权限不足 |
| **404** | 资源错误 | 资源不存在 | 提示资源不存在 |
| **429** | 频率限制 | 请求过频 | 提示用户稍后重试 |
| **500** | 服务器错误 | 服务异常 | 提示系统繁忙 |

### 🚨 前端重点关注的错误码

```javascript
// 错误处理示例
const handleApiError = (error) => {
  const code = error.code;
  
  switch(code) {
    case 401:
    case 1010: // Token过期
    case 1011: // Token无效
      // 清除本地Token，跳转登录
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      window.location.href = '/login';
      break;
      
    case 1005: // 验证码发送频繁
      showToast('验证码发送过于频繁，请60秒后重试');
      break;
      
    case 1006: // 用户已存在
      showToast('该手机号已注册，请直接登录');
      break;
      
    default:
      showToast(error.message || '操作失败，请重试');
  }
};
```

---

# 1. 用户认证模块 [已实现] 🔐

## 1.1 系统健康检查 ❤️

**接口**: `GET /health`  
**说明**: 检查系统运行状态，可用于服务监控  
**权限**: 无需认证

### 请求示例
```bash
curl http://localhost:8080/api/v1/health
```

### 响应示例
```json
{
  "code": 200,
  "message": "系统运行正常",
  "data": {
    "status": "UP",
    "timestamp": "2025-01-01T10:00:00",
    "version": "v2.0",
    "database": "connected"
  },
  "timestamp": 1640995200000
}
```

### 前端使用建议
```javascript
// 应用启动时检查服务状态
const checkSystemHealth = async () => {
  try {
    const health = await apiRequest('/health');
    if (health.status === 'UP') {
      console.log('系统正常');
    }
  } catch (error) {
    console.error('服务不可用');
    // 显示服务维护提示
  }
};
```

---

## 1.2 发送短信验证码 📱

**接口**: `POST /auth/sms/send`  
**说明**: 发送4位数字验证码，60秒防重发  
**权限**: 无需认证

### 请求参数
```json
{
  "mobile": "13800138000",      // 必填：手机号，11位数字
  "type": "register"            // 必填：类型 register|login|reset
}
```

### 参数校验规则
- `mobile`: 必须为11位手机号格式
- `type`: 只能是 `register`、`login`、`reset` 之一

### 响应示例

#### ✅ 发送成功
```json
{
  "code": 200,
  "message": "验证码发送成功",
  "data": {
    "smsId": "sms_1640995200000",    // 验证码ID，验证时需要
    "expireTime": 300                // 过期时间（秒）
  },
  "timestamp": 1640995200000
}
```

#### ❌ 发送失败
```json
{
  "code": 1005,
  "message": "短信发送过于频繁，请稍后再试",
  "data": null,
  "timestamp": 1640995200000
}
```

### 业务规则 ⚠️
- **验证码**: 4位数字（开发环境控制台显示）
- **频率限制**: 同一手机号60秒内只能发送1次
- **有效期**: 5分钟
- **每日限制**: 每个手机号最多10次

### 前端实现示例
```javascript
// 发送验证码
const sendSmsCode = async (mobile, type) => {
  try {
    const result = await apiRequest('/auth/sms/send', {
      method: 'POST',
      body: JSON.stringify({ mobile, type })
    });
    
    // 保存smsId，验证时需要
    sessionStorage.setItem('smsId', result.smsId);
    
    // 开始倒计时
    startCountdown(60);
    
    return result;
  } catch (error) {
    handleApiError(error);
  }
};

// 倒计时功能
const startCountdown = (seconds) => {
  let countdown = seconds;
  const button = document.getElementById('sendSmsBtn');
  
  const timer = setInterval(() => {
    button.textContent = `${countdown}秒后重试`;
    button.disabled = true;
    
    countdown--;
    if (countdown < 0) {
      clearInterval(timer);
      button.textContent = '发送验证码';
      button.disabled = false;
    }
  }, 1000);
};
```

---

## 1.3 用户注册 👤

**接口**: `POST /auth/register`  
**说明**: 新用户注册，需要手机验证码  
**权限**: 无需认证

### 请求参数
```json
{
  "username": "张三",              // 必填：用户昵称，2-20字符
  "mobile": "13800138000",         // 必填：手机号
  "password": "password123",       // 必填：密码，8-20位
  "confirmPassword": "password123", // 必填：确认密码
  "smsCode": "1234",              // 必填：4位验证码
  "smsId": "sms_1640995200000",   // 必填：验证码ID
  "agreeTerms": true              // 必填：是否同意条款
}
```

### 参数校验规则
- `username`: 2-20字符，不能包含特殊符号
- `mobile`: 11位手机号格式
- `password`: 8-20位，必须包含字母和数字
- `confirmPassword`: 必须与password一致
- `smsCode`: 4位数字
- `agreeTerms`: 必须为true

### 响应示例

#### ✅ 注册成功
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": "1640995200000001",
    "username": "张三",
    "mobile": "138****8000",                    // 已脱敏
    "avatar": "https://cdn.fliliy.com/avatar/default.png",
    "verified": false,
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 7200,                          // Access Token有效期（秒）
    "refreshExpiresIn": 1296000                 // Refresh Token有效期（秒）
  },
  "timestamp": 1640995200000
}
```

#### ❌ 注册失败
```json
{
  "code": 1006,
  "message": "该手机号已注册",
  "data": null,
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 注册功能
const register = async (formData) => {
  try {
    // 获取之前保存的smsId
    const smsId = sessionStorage.getItem('smsId');
    if (!smsId) {
      throw new Error('请先获取验证码');
    }
    
    const registerData = {
      ...formData,
      smsId
    };
    
    const result = await apiRequest('/auth/register', {
      method: 'POST',
      body: JSON.stringify(registerData)
    });
    
    // 保存Token
    localStorage.setItem('accessToken', result.accessToken);
    localStorage.setItem('refreshToken', result.refreshToken);
    
    // 保存用户信息
    localStorage.setItem('userInfo', JSON.stringify({
      userId: result.userId,
      username: result.username,
      mobile: result.mobile,
      avatar: result.avatar
    }));
    
    // 跳转到主页
    window.location.href = '/dashboard';
    
  } catch (error) {
    handleApiError(error);
  }
};

// 表单验证
const validateRegisterForm = (formData) => {
  const errors = [];
  
  if (!formData.username || formData.username.length < 2) {
    errors.push('用户名至少2个字符');
  }
  
  if (!/^1[3-9]\d{9}$/.test(formData.mobile)) {
    errors.push('手机号格式不正确');
  }
  
  if (formData.password !== formData.confirmPassword) {
    errors.push('两次密码输入不一致');
  }
  
  if (!/^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,20}$/.test(formData.password)) {
    errors.push('密码必须8-20位，包含字母和数字');
  }
  
  if (!formData.agreeTerms) {
    errors.push('请阅读并同意用户协议');
  }
  
  return errors;
};
```

---

## 1.4 密码登录 🔑

**接口**: `POST /auth/login/password`  
**说明**: 使用手机号+密码登录  
**权限**: 无需认证

### 请求参数
```json
{
  "mobile": "13800138000",    // 必填：手机号
  "password": "password123",  // 必填：密码
  "rememberMe": true         // 可选：记住登录状态
}
```

### 响应示例

#### ✅ 登录成功
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "userId": "1640995200000001",
    "username": "张三",
    "mobile": "138****8000",
    "email": "zhang***@example.com",           // 如果有邮箱
    "avatar": "https://cdn.fliliy.com/avatar/user.jpg",
    "verified": true,
    "status": "NORMAL",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 7200,
    "refreshExpiresIn": 1296000,
    "permissions": ["user", "seller"],         // 用户权限列表
    "lastLoginAt": "2025-01-01T08:00:00Z",    // 上次登录时间
    "registeredAt": "2024-01-01T00:00:00Z"    // 注册时间
  },
  "timestamp": 1640995200000
}
```

#### ❌ 登录失败
```json
{
  "code": 1008,
  "message": "密码错误",
  "data": null,
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 密码登录
const loginWithPassword = async (mobile, password, rememberMe = false) => {
  try {
    const result = await apiRequest('/auth/login/password', {
      method: 'POST',
      body: JSON.stringify({ mobile, password, rememberMe })
    });
    
    // 保存认证信息
    saveAuthInfo(result);
    
    // 根据rememberMe决定存储方式
    const storage = rememberMe ? localStorage : sessionStorage;
    storage.setItem('accessToken', result.accessToken);
    storage.setItem('refreshToken', result.refreshToken);
    
    return result;
    
  } catch (error) {
    // 特殊处理登录错误
    if (error.code === 1009) {
      showToast('账号已被锁定，请联系客服');
    } else if (error.code === 1008) {
      showToast('密码错误，请重试');
    } else {
      handleApiError(error);
    }
  }
};

// 保存用户信息
const saveAuthInfo = (authData) => {
  const userInfo = {
    userId: authData.userId,
    username: authData.username,
    mobile: authData.mobile,
    avatar: authData.avatar,
    verified: authData.verified,
    permissions: authData.permissions
  };
  
  localStorage.setItem('userInfo', JSON.stringify(userInfo));
  
  // 设置Token过期提醒
  const expirationTime = Date.now() + (authData.expiresIn * 1000);
  localStorage.setItem('tokenExpiration', expirationTime.toString());
};
```

---

## 1.5 验证码登录 📟

**接口**: `POST /auth/login/sms`  
**说明**: 使用手机号+验证码登录（无需密码）  
**权限**: 无需认证

### 请求参数
```json
{
  "mobile": "13800138000",         // 必填：手机号
  "smsCode": "1234",              // 必填：4位验证码
  "smsId": "sms_1640995200000"    // 必填：验证码ID
}
```

### 响应示例
同密码登录响应格式

### 前端实现示例
```javascript
// 验证码登录
const loginWithSms = async (mobile, smsCode) => {
  try {
    const smsId = sessionStorage.getItem('smsId');
    if (!smsId) {
      throw new Error('请先获取验证码');
    }
    
    const result = await apiRequest('/auth/login/sms', {
      method: 'POST',
      body: JSON.stringify({ mobile, smsCode, smsId })
    });
    
    saveAuthInfo(result);
    
    return result;
    
  } catch (error) {
    if (error.code === 1003) {
      showToast('验证码错误，请重试');
    } else if (error.code === 1004) {
      showToast('验证码已过期，请重新获取');
    } else {
      handleApiError(error);
    }
  }
};
```

---

## 1.6 Token验证 🔍

**接口**: `GET /auth/validate`  
**说明**: 验证当前Token是否有效（应用启动时调用）  
**权限**: 需要Token

### 请求头
```
Authorization: Bearer {accessToken}
```

### 响应示例

#### ✅ Token有效
```json
{
  "code": 200,
  "message": "Token有效",
  "data": {
    "valid": true,
    "userId": "1640995200000001",
    "expiresIn": 3600,              // 剩余有效时间（秒）
    "needRefresh": false,           // 是否需要刷新
    "permissions": ["user", "seller"]
  },
  "timestamp": 1640995200000
}
```

#### ❌ Token无效
```json
{
  "code": 1010,
  "message": "Token已过期",
  "data": {
    "valid": false,
    "needRefresh": true,
    "refreshUrl": "/auth/token/refresh"
  },
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 应用启动时验证Token
const validateToken = async () => {
  const token = localStorage.getItem('accessToken');
  if (!token) {
    redirectToLogin();
    return false;
  }
  
  try {
    const result = await apiRequest('/auth/validate');
    
    if (result.needRefresh) {
      // 自动刷新Token
      await refreshToken();
    }
    
    return true;
    
  } catch (error) {
    if (error.code === 1010 || error.code === 1011) {
      // Token无效，尝试刷新
      const refreshed = await refreshToken();
      return refreshed;
    }
    
    redirectToLogin();
    return false;
  }
};

// 页面路由守卫
const routeGuard = async () => {
  const isValid = await validateToken();
  if (!isValid) {
    redirectToLogin();
  }
};
```

---

## 1.7 刷新Token 🔄

**接口**: `POST /auth/token/refresh`  
**说明**: 使用RefreshToken获取新的AccessToken  
**权限**: 需要RefreshToken

### 请求参数
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 响应示例

#### ✅ 刷新成功
```json
{
  "code": 200,
  "message": "Token刷新成功",
  "data": {
    "userId": "1640995200000001",
    "username": "张三",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 7200,
    "refreshExpiresIn": 1296000
  },
  "timestamp": 1640995200000
}
```

#### ❌ 刷新失败
```json
{
  "code": 1011,
  "message": "RefreshToken无效",
  "data": null,
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 刷新Token
const refreshToken = async () => {
  try {
    const refreshToken = localStorage.getItem('refreshToken');
    if (!refreshToken) {
      redirectToLogin();
      return false;
    }
    
    const result = await apiRequest('/auth/token/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken })
    });
    
    // 更新Token
    localStorage.setItem('accessToken', result.accessToken);
    localStorage.setItem('refreshToken', result.refreshToken);
    
    // 更新过期时间
    const expirationTime = Date.now() + (result.expiresIn * 1000);
    localStorage.setItem('tokenExpiration', expirationTime.toString());
    
    return true;
    
  } catch (error) {
    // RefreshToken也无效，需要重新登录
    redirectToLogin();
    return false;
  }
};

// 自动刷新Token（在Token即将过期时调用）
const autoRefreshToken = () => {
  const expirationTime = parseInt(localStorage.getItem('tokenExpiration'));
  const currentTime = Date.now();
  const timeToExpire = expirationTime - currentTime;
  
  // 提前5分钟刷新Token
  if (timeToExpire < 5 * 60 * 1000) {
    refreshToken();
  }
};

// 定期检查Token状态
setInterval(autoRefreshToken, 60 * 1000); // 每分钟检查一次
```

---

## 1.8 退出登录 🚪

**接口**: `POST /auth/logout`  
**说明**: 退出登录，使RefreshToken失效  
**权限**: 可选Token

### 请求参数
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  // 可选
}
```

### 响应示例
```json
{
  "code": 200,
  "message": "退出登录成功",
  "data": null,
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 退出登录
const logout = async () => {
  try {
    const refreshToken = localStorage.getItem('refreshToken');
    
    // 调用后端接口
    if (refreshToken) {
      await apiRequest('/auth/logout', {
        method: 'POST',
        body: JSON.stringify({ refreshToken })
      });
    }
    
  } catch (error) {
    // 即使接口调用失败，也要清除本地数据
    console.warn('退出登录接口调用失败:', error);
  } finally {
    // 清除本地数据
    clearAuthData();
    
    // 跳转登录页
    redirectToLogin();
  }
};

// 清除认证数据
const clearAuthData = () => {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('userInfo');
  localStorage.removeItem('tokenExpiration');
  sessionStorage.clear();
};

// 跳转登录页
const redirectToLogin = () => {
  window.location.href = '/login';
};
```

---

## 1.9 获取当前用户信息 👤

**接口**: `GET /auth/me`  
**说明**: 获取当前登录用户的详细信息  
**权限**: 需要Token

### 请求头
```
Authorization: Bearer {accessToken}
```

### 响应示例
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "userId": "1640995200000001",
    "username": "张三",
    "mobile": "138****8000",
    "email": "zhang***@example.com",
    "avatar": "https://cdn.fliliy.com/avatar/user.jpg",
    "gender": 1,                        // 0未知, 1男, 2女
    "birthday": "1990-01-01",
    "location": "北京市朝阳区",
    "bio": "闲置物品转让，诚信交易",
    "verified": true,
    "status": "NORMAL",
    "registeredAt": "2023-01-01T00:00:00Z",
    "lastLoginAt": "2025-01-01T08:00:00Z",
    "stats": {
      "publishedCount": 25,           // 发布商品数
      "activeCount": 18,              // 在售商品数
      "soldCount": 15,                // 已售出数
      "boughtCount": 8,               // 购买数
      "favoriteCount": 32,            // 收藏数
      "chatCount": 12,                // 聊天数
      "points": 0,                    // 积分
      "credits": 100                  // 信用分
    },
    "rating": {
      "average": 4.8,                 // 平均评分
      "total": 20,                    // 评价总数
      "distribution": {
        "5": 15, "4": 3, "3": 2, "2": 0, "1": 0
      }
    },
    "permissions": ["user", "seller"],
    "settings": {
      "pushNotification": true,
      "emailNotification": false,
      "showMobile": false,
      "showLocation": true
    }
  },
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 获取用户信息
const getCurrentUser = async () => {
  try {
    const userInfo = await apiRequest('/auth/me');
    
    // 更新本地用户信息
    localStorage.setItem('userInfo', JSON.stringify(userInfo));
    
    // 更新UI
    updateUserProfile(userInfo);
    
    return userInfo;
    
  } catch (error) {
    handleApiError(error);
  }
};

// 更新用户界面
const updateUserProfile = (userInfo) => {
  // 更新头像
  const avatarImg = document.querySelector('.user-avatar');
  if (avatarImg) {
    avatarImg.src = userInfo.avatar;
  }
  
  // 更新用户名
  const usernameEl = document.querySelector('.username');
  if (usernameEl) {
    usernameEl.textContent = userInfo.username;
  }
  
  // 更新统计信息
  const statsEl = document.querySelector('.user-stats');
  if (statsEl) {
    statsEl.innerHTML = `
      <div class="stat-item">
        <span class="stat-value">${userInfo.stats.publishedCount}</span>
        <span class="stat-label">发布</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">${userInfo.stats.soldCount}</span>
        <span class="stat-label">售出</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">${userInfo.stats.favoriteCount}</span>
        <span class="stat-label">收藏</span>
      </div>
    `;
  }
};
```

---

# 📝 认证模块最佳实践

## 🔐 Token管理策略

### 1. **Token存储**
```javascript
// 推荐的Token存储方案
class TokenManager {
  constructor() {
    this.accessToken = null;
    this.refreshToken = null;
  }
  
  // 设置Token
  setTokens(accessToken, refreshToken, rememberMe = false) {
    const storage = rememberMe ? localStorage : sessionStorage;
    storage.setItem('accessToken', accessToken);
    storage.setItem('refreshToken', refreshToken);
    
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
  
  // 获取Token
  getAccessToken() {
    if (!this.accessToken) {
      this.accessToken = localStorage.getItem('accessToken') || 
                        sessionStorage.getItem('accessToken');
    }
    return this.accessToken;
  }
  
  // 清除Token
  clearTokens() {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    sessionStorage.removeItem('accessToken');
    sessionStorage.removeItem('refreshToken');
    
    this.accessToken = null;
    this.refreshToken = null;
  }
}

const tokenManager = new TokenManager();
```

### 2. **请求拦截器**
```javascript
// Axios请求拦截器示例
axios.interceptors.request.use(
  config => {
    const token = tokenManager.getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => Promise.reject(error)
);

// 响应拦截器
axios.interceptors.response.use(
  response => response,
  async error => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        // 自动刷新Token
        await refreshToken();
        
        // 重新发送原请求
        const newToken = tokenManager.getAccessToken();
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        
        return axios(originalRequest);
      } catch (refreshError) {
        // 刷新失败，跳转登录
        tokenManager.clearTokens();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);
```

### 3. **路由守卫**
```javascript
// Vue Router守卫示例
router.beforeEach(async (to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  
  if (requiresAuth) {
    const isValid = await validateToken();
    if (isValid) {
      next();
    } else {
      next('/login');
    }
  } else {
    next();
  }
});

// React Router守卫示例
const PrivateRoute = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(null);
  
  useEffect(() => {
    validateToken().then(setIsAuthenticated);
  }, []);
  
  if (isAuthenticated === null) {
    return <LoadingSpinner />;
  }
  
  return isAuthenticated ? children : <Navigate to="/login" />;
};
```

---

# 🚨 常见问题和解决方案

## Q1: Token过期怎么办？
**A**: 使用RefreshToken自动刷新，如果RefreshToken也过期则跳转登录页。

## Q2: 验证码收不到？
**A**: 开发环境验证码在控制台显示，生产环境检查手机号是否正确。

## Q3: 登录后页面没反应？
**A**: 检查Token是否正确保存，网络请求是否成功。

## Q4: 接口返回401错误？
**A**: 检查Token格式是否正确，是否在请求头中添加了Authorization。

## Q5: 跨域问题？
**A**: 后端已配置CORS，如仍有问题请检查请求头设置。

---

# 🔧 调试技巧

## 1. **开启Debug模式**
```javascript
// 设置debug标志
const DEBUG = process.env.NODE_ENV === 'development';

if (DEBUG) {
  // 打印所有API请求
  console.log('API Request:', url, options);
  console.log('API Response:', result);
}
```

## 2. **监控Token状态**
```javascript
// 定期检查Token状态
setInterval(() => {
  const token = tokenManager.getAccessToken();
  const expiration = localStorage.getItem('tokenExpiration');
  
  console.log('Token Status:', {
    hasToken: !!token,
    expiresIn: expiration ? new Date(parseInt(expiration)) : null
  });
}, 30000);
```

## 3. **错误上报**
```javascript
// 错误上报函数
const reportError = (error, context) => {
  if (DEBUG) {
    console.error('API Error:', error, context);
  }
  
  // 生产环境可以上报到错误监控系统
  if (process.env.NODE_ENV === 'production') {
    // Sentry.captureException(error);
  }
};
```

---

# 2. 商品展示模块 [核心功能] 🛍️

## 2.1 轮播图查询 🎠

**接口**: `GET /banners`  
**说明**: 获取首页轮播广告图  
**权限**: 无需认证

### 请求参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 否 | 轮播图类型，默认homepage |
| status | string | 否 | 状态过滤，默认active |

### 响应示例

#### ✅ 查询成功
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "title": "新年大促销",
      "image": "https://cdn.fliliy.com/banners/banner1.jpg",
      "link": "/products/category/electronics",
      "linkType": "category",        // 链接类型: category, product, external
      "sortOrder": 1,
      "isActive": true,
      "startTime": "2025-01-01T00:00:00Z",
      "endTime": "2025-02-01T00:00:00Z",
      "clickCount": 1250,
      "createdAt": "2024-12-01T00:00:00Z"
    },
    {
      "id": 2,
      "title": "热销单品推荐",
      "image": "https://cdn.fliliy.com/banners/banner2.jpg",
      "link": "/products/12345",
      "linkType": "product",
      "sortOrder": 2,
      "isActive": true,
      "startTime": "2025-01-01T00:00:00Z",
      "endTime": "2025-03-01T00:00:00Z",
      "clickCount": 980,
      "createdAt": "2024-12-01T00:00:00Z"
    }
  ],
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 获取轮播图数据
const loadBanners = async () => {
  try {
    const banners = await apiRequest('/banners?type=homepage&status=active');
    
    // 初始化轮播组件
    initCarousel(banners);
    
    return banners;
  } catch (error) {
    console.warn('轮播图加载失败:', error);
    // 轮播图失败不影响主要功能
    return [];
  }
};

// 轮播图组件初始化
const initCarousel = (banners) => {
  const carouselContainer = document.querySelector('.carousel-container');
  if (!carouselContainer || !banners.length) return;
  
  // 生成轮播图HTML
  const carouselHTML = banners.map((banner, index) => `
    <div class="carousel-item ${index === 0 ? 'active' : ''}" 
         data-link="${banner.link}" data-type="${banner.linkType}">
      <img src="${banner.image}" alt="${banner.title}" loading="lazy">
      <div class="carousel-caption">
        <h3>${banner.title}</h3>
      </div>
    </div>
  `).join('');
  
  carouselContainer.innerHTML = carouselHTML;
  
  // 绑定点击事件
  carouselContainer.addEventListener('click', (e) => {
    const item = e.target.closest('.carousel-item');
    if (item) {
      handleBannerClick(item.dataset.link, item.dataset.type);
    }
  });
  
  // 自动轮播
  startAutoCarousel();
};

// 处理轮播图点击
const handleBannerClick = (link, linkType) => {
  switch(linkType) {
    case 'category':
      window.location.href = link;
      break;
    case 'product':
      window.location.href = link;
      break;
    case 'external':
      window.open(link, '_blank');
      break;
  }
};
```

---

## 2.2 商品分类查询 🏷️

**接口**: `GET /categories`  
**说明**: 获取商品分类列表，支持多级分类  
**权限**: 无需认证

### 请求参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| parent_id | number | 否 | 父分类ID，0或不传表示顶级分类 |
| is_active | boolean | 否 | 是否只返回启用的分类，默认true |
| include_children | boolean | 否 | 是否包含子分类，默认false |

### 响应示例

#### ✅ 查询成功
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "name": "数码电子",
      "icon": "https://cdn.fliliy.com/icons/electronics.svg",
      "parentId": 0,
      "sortOrder": 1,
      "isActive": true,
      "productCount": 1250,           // 该分类下商品数量
      "children": [                   // 如果include_children=true
        {
          "id": 11,
          "name": "手机",
          "icon": "https://cdn.fliliy.com/icons/phone.svg",
          "parentId": 1,
          "sortOrder": 1,
          "isActive": true,
          "productCount": 680
        },
        {
          "id": 12,
          "name": "电脑",
          "icon": "https://cdn.fliliy.com/icons/computer.svg",
          "parentId": 1,
          "sortOrder": 2,
          "isActive": true,
          "productCount": 420
        }
      ]
    },
    {
      "id": 2,
      "name": "服装鞋帽",
      "icon": "https://cdn.fliliy.com/icons/clothing.svg",
      "parentId": 0,
      "sortOrder": 2,
      "isActive": true,
      "productCount": 890
    }
  ],
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 获取分类数据
const loadCategories = async (parentId = 0, includeChildren = true) => {
  try {
    const categories = await apiRequest('/categories', {
      method: 'GET',
      params: { 
        parent_id: parentId,
        is_active: true,
        include_children: includeChildren
      }
    });
    
    return categories;
  } catch (error) {
    console.error('分类加载失败:', error);
    return [];
  }
};

// 渲染分类导航
const renderCategories = (categories) => {
  const categoryNav = document.querySelector('.category-nav');
  if (!categoryNav) return;
  
  const categoryHTML = categories.map(category => `
    <div class="category-item" data-id="${category.id}">
      <div class="category-icon">
        <img src="${category.icon}" alt="${category.name}">
      </div>
      <div class="category-info">
        <h4>${category.name}</h4>
        <span class="product-count">${category.productCount}件商品</span>
      </div>
      ${category.children ? `
        <div class="sub-categories">
          ${category.children.map(sub => `
            <span class="sub-category" data-id="${sub.id}">${sub.name}</span>
          `).join('')}
        </div>
      ` : ''}
    </div>
  `).join('');
  
  categoryNav.innerHTML = categoryHTML;
  
  // 绑定点击事件
  categoryNav.addEventListener('click', (e) => {
    const categoryItem = e.target.closest('.category-item, .sub-category');
    if (categoryItem) {
      const categoryId = categoryItem.dataset.id;
      loadProductsByCategory(categoryId);
    }
  });
};
```

---

## 2.3 商品列表查询 📋

**接口**: `GET /products`  
**说明**: 分页获取商品列表，支持筛选和排序  
**权限**: 无需认证

### 请求参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | number | 否 | 页码，从1开始，默认1 |
| size | number | 否 | 每页数量，默认20，最大100 |
| category_id | number | 否 | 分类ID筛选 |
| condition | string | 否 | 商品状况: NEW,LIKE_NEW,GOOD,FAIR,POOR |
| min_price | number | 否 | 最低价格 |
| max_price | number | 否 | 最高价格 |
| sort | string | 否 | 排序方式: created_at_desc, price_asc, price_desc, popular |
| location | string | 否 | 位置筛选 |
| seller_id | number | 否 | 卖家ID筛选 |

### 响应示例

#### ✅ 查询成功
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "items": [
      {
        "id": 12345,
        "title": "iPhone 13 Pro Max 256GB 深空灰色",
        "description": "9成新，原装配件齐全，无拆修...",
        "price": 6999.00,
        "originalPrice": 8999.00,
        "discount": 22,                 // 折扣百分比
        "mainImage": "https://cdn.fliliy.com/products/iphone13-1.jpg",
        "images": [
          "https://cdn.fliliy.com/products/iphone13-1.jpg",
          "https://cdn.fliliy.com/products/iphone13-2.jpg"
        ],
        "condition": "LIKE_NEW",
        "conditionText": "几乎全新",
        "category": {
          "id": 11,
          "name": "手机",
          "parentName": "数码电子"
        },
        "seller": {
          "id": 98765,
          "username": "数码达人",
          "avatar": "https://cdn.fliliy.com/avatar/seller.jpg",
          "verified": true,
          "rating": 4.8,
          "soldCount": 156
        },
        "location": {
          "city": "北京",
          "district": "朝阳区",
          "detail": "国贸商圈"
        },
        "tags": ["原装配件", "无拆修", "支持验机"],
        "status": "ACTIVE",
        "viewCount": 1250,
        "favoriteCount": 89,
        "chatCount": 23,
        "publishedAt": "2025-01-01T10:00:00Z",
        "updatedAt": "2025-01-02T15:30:00Z",
        "isFavorited": false,           // 当前用户是否收藏
        "distance": 2.5                 // 距离（km），需要位置权限
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 1580,
      "totalPages": 79,
      "hasNext": true,
      "hasPrev": false
    },
    "filters": {
      "categoryCount": {               // 各分类商品数量统计
        "11": 680,
        "12": 420,
        "21": 380
      },
      "priceRange": {
        "min": 50,
        "max": 15000
      },
      "conditionCount": {
        "NEW": 120,
        "LIKE_NEW": 450,
        "GOOD": 680,
        "FAIR": 280,
        "POOR": 50
      }
    }
  },
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 商品列表管理器
class ProductListManager {
  constructor() {
    this.currentPage = 1;
    this.totalPages = 1;
    this.loading = false;
    this.products = [];
    this.filters = {};
  }
  
  // 加载商品列表
  async loadProducts(params = {}, append = false) {
    if (this.loading) return;
    
    try {
      this.loading = true;
      
      const queryParams = {
        page: append ? this.currentPage + 1 : 1,
        size: 20,
        ...this.filters,
        ...params
      };
      
      const response = await apiRequest('/products', {
        method: 'GET',
        params: queryParams
      });
      
      if (append) {
        this.products = [...this.products, ...response.items];
        this.currentPage++;
      } else {
        this.products = response.items;
        this.currentPage = response.pagination.page;
        this.totalPages = response.pagination.totalPages;
      }
      
      // 更新UI
      this.renderProducts(append);
      this.updateFilters(response.filters);
      
      return response;
      
    } catch (error) {
      console.error('商品加载失败:', error);
      this.showError('商品加载失败，请重试');
    } finally {
      this.loading = false;
    }
  }
  
  // 无限滚动加载更多
  async loadMore() {
    if (this.currentPage >= this.totalPages) return false;
    
    const response = await this.loadProducts({}, true);
    return !!response;
  }
  
  // 按分类筛选
  filterByCategory(categoryId) {
    this.filters.category_id = categoryId;
    this.loadProducts();
  }
  
  // 按价格筛选
  filterByPrice(minPrice, maxPrice) {
    this.filters.min_price = minPrice;
    this.filters.max_price = maxPrice;
    this.loadProducts();
  }
  
  // 排序
  sortBy(sortType) {
    this.filters.sort = sortType;
    this.loadProducts();
  }
  
  // 渲染商品列表
  renderProducts(append = false) {
    const container = document.querySelector('.product-list');
    if (!container) return;
    
    const productsHTML = this.products.map(product => `
      <div class="product-card" data-id="${product.id}">
        <div class="product-image">
          <img src="${product.mainImage}" alt="${product.title}" loading="lazy">
          ${product.discount ? `<span class="discount-badge">${product.discount}折</span>` : ''}
          <button class="favorite-btn ${product.isFavorited ? 'favorited' : ''}" 
                  data-id="${product.id}">
            <i class="icon-heart"></i>
          </button>
        </div>
        
        <div class="product-info">
          <h3 class="product-title">${product.title}</h3>
          <div class="product-price">
            <span class="current-price">¥${product.price}</span>
            ${product.originalPrice ? `<span class="original-price">¥${product.originalPrice}</span>` : ''}
          </div>
          
          <div class="product-condition">
            <span class="condition-tag">${product.conditionText}</span>
            ${product.tags.slice(0, 2).map(tag => `<span class="tag">${tag}</span>`).join('')}
          </div>
          
          <div class="product-meta">
            <div class="seller-info">
              <img src="${product.seller.avatar}" class="seller-avatar">
              <span class="seller-name">${product.seller.username}</span>
              ${product.seller.verified ? '<i class="icon-verified"></i>' : ''}
            </div>
            <div class="product-stats">
              <span><i class="icon-view"></i> ${product.viewCount}</span>
              <span><i class="icon-heart"></i> ${product.favoriteCount}</span>
              <span><i class="icon-location"></i> ${product.location.district}</span>
            </div>
          </div>
        </div>
      </div>
    `).join('');
    
    if (append) {
      container.insertAdjacentHTML('beforeend', productsHTML);
    } else {
      container.innerHTML = productsHTML;
    }
    
    // 绑定事件
    this.bindEvents();
  }
  
  // 绑定事件
  bindEvents() {
    const container = document.querySelector('.product-list');
    
    // 商品点击
    container.addEventListener('click', (e) => {
      const productCard = e.target.closest('.product-card');
      if (productCard && !e.target.closest('.favorite-btn')) {
        const productId = productCard.dataset.id;
        window.location.href = `/products/${productId}`;
      }
    });
    
    // 收藏按钮点击
    container.addEventListener('click', (e) => {
      if (e.target.closest('.favorite-btn')) {
        const btn = e.target.closest('.favorite-btn');
        const productId = btn.dataset.id;
        this.toggleFavorite(productId, btn);
      }
    });
  }
  
  // 切换收藏状态
  async toggleFavorite(productId, btn) {
    try {
      const response = await apiRequest(`/products/${productId}/favorite`, {
        method: 'POST'
      });
      
      btn.classList.toggle('favorited', response.isFavorited);
      
      // 更新收藏数
      const productCard = btn.closest('.product-card');
      const favoriteCount = productCard.querySelector('.icon-heart + span');
      if (favoriteCount) {
        favoriteCount.textContent = response.favoriteCount;
      }
      
    } catch (error) {
      if (error.code === 401) {
        showToast('请先登录');
        // 可选择跳转登录页
      } else {
        showToast('操作失败，请重试');
      }
    }
  }
}

// 初始化商品列表管理器
const productManager = new ProductListManager();

// 页面加载时获取商品列表
document.addEventListener('DOMContentLoaded', () => {
  productManager.loadProducts();
});

// 无限滚动
let scrollTimeout;
window.addEventListener('scroll', () => {
  clearTimeout(scrollTimeout);
  scrollTimeout = setTimeout(() => {
    const scrollHeight = document.documentElement.scrollHeight;
    const scrollTop = document.documentElement.scrollTop;
    const clientHeight = document.documentElement.clientHeight;
    
    // 距离底部100px时加载更多
    if (scrollTop + clientHeight >= scrollHeight - 100) {
      productManager.loadMore();
    }
  }, 100);
});
```

---

## 2.4 商品搜索 🔍

**接口**: `GET /products/search`  
**说明**: 全文搜索商品，支持标题和描述搜索  
**权限**: 无需认证

### 请求参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词 |
| page | number | 否 | 页码，默认1 |
| size | number | 否 | 每页数量，默认20 |
| category_id | number | 否 | 分类筛选 |
| min_price | number | 否 | 价格筛选 |
| max_price | number | 否 | 价格筛选 |
| sort | string | 否 | 排序: relevance, created_at_desc, price_asc, price_desc |

### 响应示例

响应格式与商品列表相同，但会额外包含搜索相关信息：

```json
{
  "code": 200,
  "message": "搜索成功",
  "data": {
    "items": [...],  // 商品列表格式相同
    "searchInfo": {
      "keyword": "iPhone",
      "total": 156,
      "searchTime": 23,        // 搜索耗时(ms)
      "suggestions": [         // 搜索建议
        "iPhone 13",
        "iPhone 12",
        "iPhone Pro"
      ],
      "corrections": null      // 拼写纠正建议
    },
    "pagination": {...}
  },
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 搜索功能管理器
class SearchManager {
  constructor() {
    this.searchHistory = JSON.parse(localStorage.getItem('searchHistory') || '[]');
    this.searchInput = document.querySelector('.search-input');
    this.searchButton = document.querySelector('.search-button');
    this.searchSuggestions = document.querySelector('.search-suggestions');
    
    this.initSearch();
  }
  
  // 初始化搜索功能
  initSearch() {
    // 搜索按钮点击
    this.searchButton?.addEventListener('click', () => {
      const keyword = this.searchInput.value.trim();
      if (keyword) {
        this.performSearch(keyword);
      }
    });
    
    // 回车搜索
    this.searchInput?.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        const keyword = e.target.value.trim();
        if (keyword) {
          this.performSearch(keyword);
        }
      }
    });
    
    // 输入时显示建议
    let suggestionTimeout;
    this.searchInput?.addEventListener('input', (e) => {
      const keyword = e.target.value.trim();
      
      clearTimeout(suggestionTimeout);
      if (keyword.length >= 2) {
        suggestionTimeout = setTimeout(() => {
          this.showSearchSuggestions(keyword);
        }, 300);
      } else {
        this.hideSearchSuggestions();
      }
    });
    
    // 点击外部隐藏建议
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.search-container')) {
        this.hideSearchSuggestions();
      }
    });
  }
  
  // 执行搜索
  async performSearch(keyword) {
    try {
      // 添加到搜索历史
      this.addSearchHistory(keyword);
      
      // 执行搜索请求
      const response = await apiRequest('/products/search', {
        method: 'GET',
        params: { 
          keyword,
          page: 1,
          size: 20
        }
      });
      
      // 隐藏搜索建议
      this.hideSearchSuggestions();
      
      // 跳转到搜索结果页面或更新当前页面
      this.displaySearchResults(response, keyword);
      
      return response;
      
    } catch (error) {
      console.error('搜索失败:', error);
      showToast('搜索失败，请重试');
    }
  }
  
  // 显示搜索建议
  showSearchSuggestions(keyword) {
    if (!this.searchSuggestions) return;
    
    // 从搜索历史中匹配
    const historySuggestions = this.searchHistory
      .filter(item => item.toLowerCase().includes(keyword.toLowerCase()))
      .slice(0, 5);
    
    // 热门搜索建议（可以从后端获取）
    const hotSuggestions = this.getHotSearchKeywords(keyword);
    
    const allSuggestions = [...new Set([...historySuggestions, ...hotSuggestions])];
    
    if (allSuggestions.length === 0) {
      this.hideSearchSuggestions();
      return;
    }
    
    const suggestionsHTML = allSuggestions.map(suggestion => `
      <div class="suggestion-item" data-keyword="${suggestion}">
        <i class="icon-search"></i>
        <span>${this.highlightKeyword(suggestion, keyword)}</span>
      </div>
    `).join('');
    
    this.searchSuggestions.innerHTML = suggestionsHTML;
    this.searchSuggestions.style.display = 'block';
    
    // 绑定建议点击事件
    this.searchSuggestions.addEventListener('click', (e) => {
      const item = e.target.closest('.suggestion-item');
      if (item) {
        const keyword = item.dataset.keyword;
        this.searchInput.value = keyword;
        this.performSearch(keyword);
      }
    });
  }
  
  // 隐藏搜索建议
  hideSearchSuggestions() {
    if (this.searchSuggestions) {
      this.searchSuggestions.style.display = 'none';
    }
  }
  
  // 高亮关键词
  highlightKeyword(text, keyword) {
    const regex = new RegExp(`(${keyword})`, 'gi');
    return text.replace(regex, '<mark>$1</mark>');
  }
  
  // 添加搜索历史
  addSearchHistory(keyword) {
    // 移除重复项
    this.searchHistory = this.searchHistory.filter(item => item !== keyword);
    
    // 添加到开头
    this.searchHistory.unshift(keyword);
    
    // 限制历史记录数量
    this.searchHistory = this.searchHistory.slice(0, 10);
    
    // 保存到本地存储
    localStorage.setItem('searchHistory', JSON.stringify(this.searchHistory));
  }
  
  // 获取热门搜索关键词（示例数据）
  getHotSearchKeywords(keyword) {
    const hotKeywords = [
      'iPhone 13', 'MacBook Pro', '游戏机', '相机', '手表',
      '耳机', '键盘', '显示器', '平板电脑', '充电器'
    ];
    
    return hotKeywords
      .filter(item => item.toLowerCase().includes(keyword.toLowerCase()))
      .slice(0, 3);
  }
  
  // 显示搜索结果
  displaySearchResults(response, keyword) {
    const { items, searchInfo, pagination } = response;
    
    // 更新页面标题
    document.title = `"${keyword}"的搜索结果 - Fliliy二手平台`;
    
    // 显示搜索统计信息
    const searchStats = document.querySelector('.search-stats');
    if (searchStats) {
      searchStats.innerHTML = `
        <div class="search-keyword">搜索关键词：<strong>${keyword}</strong></div>
        <div class="search-count">找到 <strong>${searchInfo.total}</strong> 个结果</div>
        <div class="search-time">搜索用时：${searchInfo.searchTime}ms</div>
      `;
    }
    
    // 显示搜索建议
    if (searchInfo.suggestions && searchInfo.suggestions.length > 0) {
      const suggestionsContainer = document.querySelector('.search-corrections');
      if (suggestionsContainer) {
        suggestionsContainer.innerHTML = `
          <div class="suggestions-title">您是否要找：</div>
          <div class="suggestions-list">
            ${searchInfo.suggestions.map(suggestion => `
              <a href="#" class="suggestion-link" data-keyword="${suggestion}">${suggestion}</a>
            `).join('')}
          </div>
        `;
        
        // 绑定建议点击事件
        suggestionsContainer.addEventListener('click', (e) => {
          if (e.target.classList.contains('suggestion-link')) {
            e.preventDefault();
            const newKeyword = e.target.dataset.keyword;
            this.searchInput.value = newKeyword;
            this.performSearch(newKeyword);
          }
        });
      }
    }
    
    // 使用商品管理器显示结果
    productManager.products = items;
    productManager.totalPages = pagination.totalPages;
    productManager.currentPage = pagination.page;
    productManager.renderProducts();
  }
}

// 初始化搜索管理器
const searchManager = new SearchManager();
```

---

## 2.5 商品详情查询 📝

**接口**: `GET /products/{productId}`  
**说明**: 获取商品详细信息  
**权限**: 无需认证（但登录后会返回更多信息）

### 路径参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| productId | number | 是 | 商品ID |

### 响应示例

#### ✅ 查询成功
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": 12345,
    "title": "iPhone 13 Pro Max 256GB 深空灰色",
    "description": "9成新iPhone 13 Pro Max，深空灰色256GB版本。\n\n商品详情：\n- 购买时间：2022年10月\n- 使用状况：日常轻度使用，保护很好\n- 配件情况：原装充电线、说明书、包装盒齐全\n- 功能测试：所有功能正常，电池健康度92%\n- 外观状况：正面完美，背面有轻微使用痕迹\n\n交易说明：\n- 支持当面验机\n- 仅限北京同城交易\n- 支持7天无理由退换",
    "price": 6999.00,
    "originalPrice": 8999.00,
    "category": {
      "id": 11,
      "name": "手机",
      "parentId": 1,
      "parentName": "数码电子",
      "breadcrumb": "数码电子 > 手机"
    },
    "images": [
      "https://cdn.fliliy.com/products/iphone13-1.jpg",
      "https://cdn.fliliy.com/products/iphone13-2.jpg",
      "https://cdn.fliliy.com/products/iphone13-3.jpg",
      "https://cdn.fliliy.com/products/iphone13-4.jpg"
    ],
    "condition": "LIKE_NEW",
    "conditionText": "几乎全新",
    "conditionDescription": "外观完好，功能正常，有轻微使用痕迹",
    "usageInfo": {
      "type": "TIME",                  // TIME时间, COUNT次数, OTHER其他
      "value": 4,
      "unit": "个月",
      "description": "使用4个月"
    },
    "warrantyInfo": {
      "hasWarranty": false,
      "warrantyPeriod": null,
      "warrantyDescription": "已过保修期"
    },
    "location": {
      "province": "北京市",
      "city": "北京市",
      "district": "朝阳区",
      "detail": "国贸商圈",
      "coordinates": {
        "latitude": 39.9042,
        "longitude": 116.4074
      }
    },
    "tags": ["原装配件", "无拆修", "支持验机", "7天退换", "当面交易"],
    "seller": {
      "id": 98765,
      "username": "数码达人",
      "avatar": "https://cdn.fliliy.com/avatar/seller.jpg",
      "verified": true,
      "verifiedType": "PHONE",          // 认证类型
      "rating": 4.8,
      "reviewCount": 128,
      "soldCount": 156,
      "activeCount": 23,
      "joinedAt": "2023-03-15T00:00:00Z",
      "lastActiveAt": "2025-01-02T10:30:00Z",
      "responseRate": 95,               // 回复率%
      "responseTime": "1小时内",         // 平均回复时间
      "deliveryScore": 4.9,            // 发货速度评分
      "serviceScore": 4.7,             // 服务态度评分
      "location": "北京市朝阳区"
    },
    "status": "ACTIVE",
    "publishedAt": "2025-01-01T10:00:00Z",
    "updatedAt": "2025-01-02T15:30:00Z",
    "viewCount": 1250,
    "favoriteCount": 89,
    "shareCount": 34,
    "chatCount": 23,
    "isFavorited": false,              // 当前用户是否收藏
    "isOwner": false,                  // 是否为商品发布者
    "canContact": true,                // 是否可以联系卖家
    "similarProducts": [               // 相似商品推荐
      {
        "id": 12346,
        "title": "iPhone 13 Pro 128GB 金色",
        "price": 6299.00,
        "mainImage": "https://cdn.fliliy.com/products/similar1.jpg",
        "condition": "GOOD"
      }
    ],
    "viewHistory": [                   // 浏览历史（需要登录）
      {
        "viewedAt": "2025-01-02T14:20:00Z",
        "userAgent": "Mobile",
        "source": "search"
      }
    ]
  },
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 商品详情页管理器
class ProductDetailManager {
  constructor(productId) {
    this.productId = productId;
    this.product = null;
    this.currentImageIndex = 0;
    this.init();
  }
  
  // 初始化
  async init() {
    await this.loadProductDetail();
    this.initImageGallery();
    this.bindEvents();
  }
  
  // 加载商品详情
  async loadProductDetail() {
    try {
      this.showLoading(true);
      
      const product = await apiRequest(`/products/${this.productId}`);
      this.product = product;
      
      // 渲染页面
      this.renderProductDetail();
      
      // 更新页面SEO信息
      this.updatePageSEO();
      
    } catch (error) {
      if (error.code === 404) {
        this.showNotFound();
      } else {
        this.showError('商品加载失败，请重试');
      }
    } finally {
      this.showLoading(false);
    }
  }
  
  // 渲染商品详情
  renderProductDetail() {
    const { product } = this;
    
    // 渲染图片画廊
    this.renderImageGallery(product.images);
    
    // 渲染商品信息
    this.renderProductInfo(product);
    
    // 渲染卖家信息
    this.renderSellerInfo(product.seller);
    
    // 渲染相似商品
    this.renderSimilarProducts(product.similarProducts);
  }
  
  // 渲染图片画廊
  renderImageGallery(images) {
    const gallery = document.querySelector('.product-gallery');
    if (!gallery || !images.length) return;
    
    gallery.innerHTML = `
      <div class="main-image">
        <img id="mainImage" src="${images[0]}" alt="商品图片">
        <button class="fullscreen-btn" title="全屏查看">
          <i class="icon-fullscreen"></i>
        </button>
      </div>
      
      <div class="thumbnail-list">
        ${images.map((image, index) => `
          <div class="thumbnail ${index === 0 ? 'active' : ''}" data-index="${index}">
            <img src="${image}" alt="商品图片${index + 1}">
          </div>
        `).join('')}
      </div>
      
      ${images.length > 1 ? `
        <button class="prev-btn" title="上一张">
          <i class="icon-chevron-left"></i>
        </button>
        <button class="next-btn" title="下一张">
          <i class="icon-chevron-right"></i>
        </button>
      ` : ''}
    `;
  }
  
  // 渲染商品信息
  renderProductInfo(product) {
    const infoContainer = document.querySelector('.product-info');
    if (!infoContainer) return;
    
    infoContainer.innerHTML = `
      <div class="product-header">
        <h1 class="product-title">${product.title}</h1>
        <div class="product-actions">
          <button class="favorite-btn ${product.isFavorited ? 'favorited' : ''}" 
                  data-id="${product.id}">
            <i class="icon-heart"></i>
            <span>${product.favoriteCount}</span>
          </button>
          <button class="share-btn" data-id="${product.id}">
            <i class="icon-share"></i>
            <span>分享</span>
          </button>
        </div>
      </div>
      
      <div class="price-section">
        <div class="current-price">¥${product.price.toFixed(2)}</div>
        ${product.originalPrice ? `
          <div class="original-price">原价: ¥${product.originalPrice.toFixed(2)}</div>
          <div class="discount">
            ${Math.round((1 - product.price / product.originalPrice) * 100)}折
          </div>
        ` : ''}
      </div>
      
      <div class="product-meta">
        <div class="meta-row">
          <span class="meta-label">商品状况:</span>
          <span class="meta-value condition-${product.condition.toLowerCase()}">
            ${product.conditionText}
          </span>
        </div>
        
        <div class="meta-row">
          <span class="meta-label">使用情况:</span>
          <span class="meta-value">${product.usageInfo.description}</span>
        </div>
        
        <div class="meta-row">
          <span class="meta-label">所在位置:</span>
          <span class="meta-value">
            <i class="icon-location"></i>
            ${product.location.district}
          </span>
        </div>
        
        <div class="meta-row">
          <span class="meta-label">发布时间:</span>
          <span class="meta-value">${this.formatDate(product.publishedAt)}</span>
        </div>
        
        <div class="meta-row">
          <span class="meta-label">浏览次数:</span>
          <span class="meta-value">${product.viewCount} 次</span>
        </div>
      </div>
      
      <div class="product-tags">
        ${product.tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
      </div>
      
      <div class="product-description">
        <h3>商品描述</h3>
        <div class="description-content">
          ${product.description.replace(/\n/g, '<br>')}
        </div>
      </div>
      
      <div class="action-buttons">
        ${product.canContact ? `
          <button class="contact-btn primary" data-seller-id="${product.seller.id}">
            <i class="icon-message"></i>
            联系卖家
          </button>
        ` : `
          <button class="contact-btn disabled" disabled>
            无法联系
          </button>
        `}
        
        <button class="report-btn secondary">
          <i class="icon-flag"></i>
          举报商品
        </button>
      </div>
    `;
  }
  
  // 渲染卖家信息
  renderSellerInfo(seller) {
    const sellerContainer = document.querySelector('.seller-info');
    if (!sellerContainer) return;
    
    sellerContainer.innerHTML = `
      <div class="seller-header">
        <div class="seller-avatar">
          <img src="${seller.avatar}" alt="${seller.username}">
          ${seller.verified ? '<i class="verified-badge" title="已认证"></i>' : ''}
        </div>
        
        <div class="seller-basic">
          <h3 class="seller-name">${seller.username}</h3>
          <div class="seller-rating">
            <div class="stars">
              ${this.renderStars(seller.rating)}
            </div>
            <span class="rating-text">${seller.rating} (${seller.reviewCount}评价)</span>
          </div>
          <div class="seller-location">
            <i class="icon-location"></i>
            ${seller.location}
          </div>
        </div>
        
        <button class="view-profile-btn" data-seller-id="${seller.id}">
          查看主页
        </button>
      </div>
      
      <div class="seller-stats">
        <div class="stat-item">
          <div class="stat-value">${seller.soldCount}</div>
          <div class="stat-label">已售出</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">${seller.activeCount}</div>
          <div class="stat-label">在售中</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">${seller.responseRate}%</div>
          <div class="stat-label">回复率</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">${seller.responseTime}</div>
          <div class="stat-label">回复时间</div>
        </div>
      </div>
      
      <div class="seller-scores">
        <div class="score-item">
          <span class="score-label">发货速度:</span>
          <div class="score-stars">${this.renderStars(seller.deliveryScore)}</div>
          <span class="score-value">${seller.deliveryScore}</span>
        </div>
        <div class="score-item">
          <span class="score-label">服务态度:</span>
          <div class="score-stars">${this.renderStars(seller.serviceScore)}</div>
          <span class="score-value">${seller.serviceScore}</span>
        </div>
      </div>
      
      <div class="seller-time">
        <div class="join-time">
          <i class="icon-calendar"></i>
          ${this.formatDate(seller.joinedAt)} 加入
        </div>
        <div class="last-active">
          <i class="icon-clock"></i>
          ${this.formatDate(seller.lastActiveAt)} 活跃
        </div>
      </div>
    `;
  }
  
  // 初始化图片画廊
  initImageGallery() {
    const gallery = document.querySelector('.product-gallery');
    if (!gallery) return;
    
    // 缩略图点击
    gallery.addEventListener('click', (e) => {
      const thumbnail = e.target.closest('.thumbnail');
      if (thumbnail) {
        const index = parseInt(thumbnail.dataset.index);
        this.switchImage(index);
      }
    });
    
    // 前后切换按钮
    gallery.addEventListener('click', (e) => {
      if (e.target.closest('.prev-btn')) {
        this.switchImage(this.currentImageIndex - 1);
      } else if (e.target.closest('.next-btn')) {
        this.switchImage(this.currentImageIndex + 1);
      } else if (e.target.closest('.fullscreen-btn')) {
        this.openFullscreen();
      }
    });
    
    // 键盘导航
    document.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') {
        this.switchImage(this.currentImageIndex - 1);
      } else if (e.key === 'ArrowRight') {
        this.switchImage(this.currentImageIndex + 1);
      }
    });
  }
  
  // 切换图片
  switchImage(index) {
    const images = this.product.images;
    if (index < 0) index = images.length - 1;
    if (index >= images.length) index = 0;
    
    this.currentImageIndex = index;
    
    // 更新主图
    const mainImage = document.getElementById('mainImage');
    if (mainImage) {
      mainImage.src = images[index];
    }
    
    // 更新缩略图状态
    const thumbnails = document.querySelectorAll('.thumbnail');
    thumbnails.forEach((thumb, i) => {
      thumb.classList.toggle('active', i === index);
    });
  }
  
  // 绑定事件
  bindEvents() {
    const container = document.querySelector('.product-detail-container');
    
    // 收藏按钮
    container.addEventListener('click', (e) => {
      if (e.target.closest('.favorite-btn')) {
        this.toggleFavorite();
      }
    });
    
    // 分享按钮
    container.addEventListener('click', (e) => {
      if (e.target.closest('.share-btn')) {
        this.shareProduct();
      }
    });
    
    // 联系卖家
    container.addEventListener('click', (e) => {
      if (e.target.closest('.contact-btn:not(.disabled)')) {
        this.contactSeller();
      }
    });
    
    // 举报按钮
    container.addEventListener('click', (e) => {
      if (e.target.closest('.report-btn')) {
        this.reportProduct();
      }
    });
  }
  
  // 切换收藏状态
  async toggleFavorite() {
    try {
      const response = await apiRequest(`/products/${this.productId}/favorite`, {
        method: 'POST'
      });
      
      const btn = document.querySelector('.favorite-btn');
      const countSpan = btn.querySelector('span');
      
      btn.classList.toggle('favorited', response.isFavorited);
      countSpan.textContent = response.favoriteCount;
      
      showToast(response.isFavorited ? '收藏成功' : '取消收藏');
      
    } catch (error) {
      if (error.code === 401) {
        showToast('请先登录');
      } else {
        showToast('操作失败，请重试');
      }
    }
  }
  
  // 分享商品
  async shareProduct() {
    const shareData = {
      title: this.product.title,
      text: `${this.product.title} - 仅售¥${this.product.price}`,
      url: window.location.href
    };
    
    try {
      if (navigator.share) {
        await navigator.share(shareData);
      } else {
        // 降级处理：复制链接
        await navigator.clipboard.writeText(window.location.href);
        showToast('链接已复制到剪贴板');
      }
    } catch (error) {
      console.warn('分享失败:', error);
    }
  }
  
  // 联系卖家
  contactSeller() {
    // 跳转到聊天页面或打开聊天窗口
    const chatUrl = `/chat/${this.product.seller.id}?productId=${this.productId}`;
    window.location.href = chatUrl;
  }
  
  // 工具方法：格式化日期
  formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    if (days > 0) {
      return `${days}天前`;
    } else if (hours > 0) {
      return `${hours}小时前`;
    } else if (minutes > 0) {
      return `${minutes}分钟前`;
    } else {
      return '刚刚';
    }
  }
  
  // 工具方法：渲染星级
  renderStars(rating, maxStars = 5) {
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;
    const emptyStars = maxStars - fullStars - (hasHalfStar ? 1 : 0);
    
    return [
      ...Array(fullStars).fill('<i class="icon-star-full"></i>'),
      ...(hasHalfStar ? ['<i class="icon-star-half"></i>'] : []),
      ...Array(emptyStars).fill('<i class="icon-star-empty"></i>')
    ].join('');
  }
}

// 页面加载时初始化商品详情
document.addEventListener('DOMContentLoaded', () => {
  const productId = getProductIdFromUrl(); // 从URL获取商品ID的函数
  if (productId) {
    new ProductDetailManager(productId);
  }
});

// 从URL获取商品ID的辅助函数
function getProductIdFromUrl() {
  const pathMatch = window.location.pathname.match(/\/products\/(\d+)/);
  return pathMatch ? parseInt(pathMatch[1]) : null;
}
```

---

## 2.6 文件上传接口 📁

**接口**: `POST /files/upload`  
**说明**: 上传商品图片、头像等文件  
**权限**: 需要Token

### 请求参数 (multipart/form-data)
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file | File | 是 | 文件对象 |
| type | string | 是 | 文件类型: product, avatar, chat |
| compress | boolean | 否 | 是否压缩，默认true |

### 文件限制
- **商品图片**: jpg/png/webp，最大10MB，最多20张
- **头像**: jpg/png，最大5MB，自动裁剪正方形
- **聊天图片**: jpg/png/gif，最大20MB，保持原始质量

### 响应示例

#### ✅ 上传成功
```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "fileId": "file_1640995200001",
    "originalName": "product_image.jpg",
    "fileName": "1640995200_a8b9c7d2.jpg",
    "url": "https://cdn.fliliy.com/uploads/products/1640995200_a8b9c7d2.jpg",
    "thumbnailUrl": "https://cdn.fliliy.com/uploads/products/thumb_1640995200_a8b9c7d2.jpg",
    "fileSize": 2048576,
    "mimeType": "image/jpeg",
    "width": 1920,
    "height": 1080,
    "uploadTime": "2025-01-01T10:00:00Z"
  },
  "timestamp": 1640995200000
}
```

#### ❌ 上传失败
```json
{
  "code": 2001,
  "message": "文件大小超出限制",
  "data": {
    "maxSize": "10MB",
    "currentSize": "12MB"
  },
  "timestamp": 1640995200000
}
```

### 前端实现示例
```javascript
// 文件上传管理器
class FileUploadManager {
  constructor() {
    this.uploadQueue = [];
    this.maxConcurrent = 3;
    this.activeUploads = 0;
  }
  
  // 上传单个文件
  async uploadFile(file, type = 'product', compress = true) {
    try {
      // 文件验证
      this.validateFile(file, type);
      
      const formData = new FormData();
      formData.append('file', file);
      formData.append('type', type);
      formData.append('compress', compress);
      
      const response = await fetch(`${API_BASE_URL}/files/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
        },
        body: formData
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      const result = await response.json();
      
      if (result.code !== 200) {
        throw new Error(result.message);
      }
      
      return result.data;
      
    } catch (error) {
      console.error('文件上传失败:', error);
      throw error;
    }
  }
  
  // 批量上传文件
  async uploadMultiple(files, type = 'product', onProgress) {
    const results = [];
    
    for (let i = 0; i < files.length; i++) {
      try {
        const result = await this.uploadFile(files[i], type);
        results.push({ success: true, file: files[i], data: result });
        
        // 进度回调
        if (onProgress) {
          onProgress({
            completed: i + 1,
            total: files.length,
            percentage: Math.round(((i + 1) / files.length) * 100)
          });
        }
        
      } catch (error) {
        results.push({ success: false, file: files[i], error });
      }
    }
    
    return results;
  }
  
  // 文件验证
  validateFile(file, type) {
    const limits = {
      product: { maxSize: 10 * 1024 * 1024, types: ['image/jpeg', 'image/png', 'image/webp'] },
      avatar: { maxSize: 5 * 1024 * 1024, types: ['image/jpeg', 'image/png'] },
      chat: { maxSize: 20 * 1024 * 1024, types: ['image/jpeg', 'image/png', 'image/gif'] }
    };
    
    const limit = limits[type];
    if (!limit) {
      throw new Error('不支持的文件类型');
    }
    
    if (file.size > limit.maxSize) {
      const maxSizeMB = Math.round(limit.maxSize / (1024 * 1024));
      throw new Error(`文件大小不能超过${maxSizeMB}MB`);
    }
    
    if (!limit.types.includes(file.type)) {
      throw new Error('不支持的文件格式');
    }
  }
  
  // 图片预压缩（在客户端进行）
  async compressImage(file, quality = 0.8, maxWidth = 1920) {
    return new Promise((resolve) => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      const img = new Image();
      
      img.onload = () => {
        // 计算新尺寸
        let { width, height } = img;
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }
        
        canvas.width = width;
        canvas.height = height;
        
        // 绘制压缩后的图片
        ctx.drawImage(img, 0, 0, width, height);
        
        canvas.toBlob(resolve, file.type, quality);
      };
      
      img.src = URL.createObjectURL(file);
    });
  }
}

// 图片上传组件
class ImageUploadComponent {
  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      maxFiles: 20,
      type: 'product',
      compress: true,
      preview: true,
      ...options
    };
    
    this.files = [];
    this.uploadManager = new FileUploadManager();
    
    this.init();
  }
  
  init() {
    this.render();
    this.bindEvents();
  }
  
  render() {
    this.container.innerHTML = `
      <div class="image-upload-area">
        <div class="upload-trigger">
          <input type="file" class="file-input" multiple accept="image/*" style="display: none;">
          <div class="upload-placeholder">
            <i class="icon-plus"></i>
            <span>点击上传图片</span>
            <div class="upload-tips">
              支持jpg/png格式，最多${this.options.maxFiles}张
            </div>
          </div>
        </div>
        
        <div class="image-preview-list"></div>
        
        <div class="upload-progress" style="display: none;">
          <div class="progress-bar">
            <div class="progress-fill"></div>
          </div>
          <div class="progress-text">0%</div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    const fileInput = this.container.querySelector('.file-input');
    const uploadTrigger = this.container.querySelector('.upload-trigger');
    
    // 点击触发文件选择
    uploadTrigger.addEventListener('click', () => {
      if (this.files.length < this.options.maxFiles) {
        fileInput.click();
      }
    });
    
    // 文件选择
    fileInput.addEventListener('change', (e) => {
      this.handleFiles(Array.from(e.target.files));
      e.target.value = ''; // 清除input值，允许重复选择同一文件
    });
    
    // 拖拽上传
    uploadTrigger.addEventListener('dragover', (e) => {
      e.preventDefault();
      uploadTrigger.classList.add('drag-over');
    });
    
    uploadTrigger.addEventListener('dragleave', () => {
      uploadTrigger.classList.remove('drag-over');
    });
    
    uploadTrigger.addEventListener('drop', (e) => {
      e.preventDefault();
      uploadTrigger.classList.remove('drag-over');
      
      const files = Array.from(e.dataTransfer.files).filter(file => 
        file.type.startsWith('image/')
      );
      
      this.handleFiles(files);
    });
  }
  
  // 处理选择的文件
  async handleFiles(newFiles) {
    // 检查文件数量限制
    const remainingSlots = this.options.maxFiles - this.files.length;
    if (newFiles.length > remainingSlots) {
      newFiles = newFiles.slice(0, remainingSlots);
      showToast(`最多只能上传${this.options.maxFiles}张图片`);
    }
    
    // 添加到文件列表
    for (const file of newFiles) {
      try {
        this.uploadManager.validateFile(file, this.options.type);
        
        const fileItem = {
          file,
          id: Date.now() + Math.random(),
          status: 'pending',
          preview: URL.createObjectURL(file)
        };
        
        this.files.push(fileItem);
        this.renderPreview(fileItem);
        
      } catch (error) {
        showToast(`${file.name}: ${error.message}`);
      }
    }
    
    // 开始上传
    await this.startUpload();
  }
  
  // 开始上传
  async startUpload() {
    const pendingFiles = this.files.filter(item => item.status === 'pending');
    if (pendingFiles.length === 0) return;
    
    this.showProgress(true);
    
    let completed = 0;
    const total = pendingFiles.length;
    
    for (const fileItem of pendingFiles) {
      try {
        fileItem.status = 'uploading';
        this.updatePreviewStatus(fileItem);
        
        const result = await this.uploadManager.uploadFile(
          fileItem.file, 
          this.options.type, 
          this.options.compress
        );
        
        fileItem.status = 'success';
        fileItem.data = result;
        this.updatePreviewStatus(fileItem);
        
      } catch (error) {
        fileItem.status = 'error';
        fileItem.error = error.message;
        this.updatePreviewStatus(fileItem);
      }
      
      completed++;
      this.updateProgress(completed, total);
    }
    
    setTimeout(() => {
      this.showProgress(false);
    }, 1000);
    
    // 触发上传完成事件
    this.onUploadComplete();
  }
  
  // 渲染图片预览
  renderPreview(fileItem) {
    const previewList = this.container.querySelector('.image-preview-list');
    
    const previewItem = document.createElement('div');
    previewItem.className = 'image-preview-item';
    previewItem.dataset.id = fileItem.id;
    
    previewItem.innerHTML = `
      <div class="preview-image">
        <img src="${fileItem.preview}" alt="预览图">
        <div class="preview-overlay">
          <div class="upload-status">
            <i class="icon-clock"></i>
          </div>
        </div>
      </div>
      <button class="remove-btn" title="删除">
        <i class="icon-close"></i>
      </button>
    `;
    
    // 绑定删除事件
    previewItem.querySelector('.remove-btn').addEventListener('click', () => {
      this.removeFile(fileItem.id);
    });
    
    previewList.appendChild(previewItem);
  }
  
  // 更新预览状态
  updatePreviewStatus(fileItem) {
    const previewItem = this.container.querySelector(`[data-id="${fileItem.id}"]`);
    if (!previewItem) return;
    
    const statusIcon = previewItem.querySelector('.upload-status i');
    const overlay = previewItem.querySelector('.preview-overlay');
    
    overlay.className = 'preview-overlay';
    
    switch (fileItem.status) {
      case 'pending':
        statusIcon.className = 'icon-clock';
        break;
      case 'uploading':
        statusIcon.className = 'icon-loading spinning';
        overlay.classList.add('uploading');
        break;
      case 'success':
        statusIcon.className = 'icon-check';
        overlay.classList.add('success');
        break;
      case 'error':
        statusIcon.className = 'icon-close';
        overlay.classList.add('error');
        break;
    }
  }
  
  // 移除文件
  removeFile(fileId) {
    this.files = this.files.filter(item => item.id !== fileId);
    
    const previewItem = this.container.querySelector(`[data-id="${fileId}"]`);
    if (previewItem) {
      previewItem.remove();
    }
    
    this.onUploadComplete();
  }
  
  // 显示/隐藏进度条
  showProgress(show) {
    const progressContainer = this.container.querySelector('.upload-progress');
    progressContainer.style.display = show ? 'block' : 'none';
  }
  
  // 更新上传进度
  updateProgress(completed, total) {
    const percentage = Math.round((completed / total) * 100);
    
    const progressFill = this.container.querySelector('.progress-fill');
    const progressText = this.container.querySelector('.progress-text');
    
    progressFill.style.width = `${percentage}%`;
    progressText.textContent = `${percentage}% (${completed}/${total})`;
  }
  
  // 获取上传成功的文件列表
  getUploadedFiles() {
    return this.files
      .filter(item => item.status === 'success')
      .map(item => item.data);
  }
  
  // 上传完成回调
  onUploadComplete() {
    const uploadedFiles = this.getUploadedFiles();
    
    // 触发自定义事件
    const event = new CustomEvent('upload-complete', {
      detail: {
        files: uploadedFiles,
        total: this.files.length
      }
    });
    
    this.container.dispatchEvent(event);
    
    // 如果有回调函数
    if (this.options.onComplete) {
      this.options.onComplete(uploadedFiles);
    }
  }
}

// 使用示例
document.addEventListener('DOMContentLoaded', () => {
  // 初始化商品图片上传组件
  const productImageUpload = document.querySelector('#product-images');
  if (productImageUpload) {
    const imageUpload = new ImageUploadComponent(productImageUpload, {
      maxFiles: 20,
      type: 'product',
      onComplete: (files) => {
        console.log('商品图片上传完成:', files);
        // 保存图片URL到表单或变量中
        window.productImages = files.map(file => file.url);
      }
    });
  }
  
  // 初始化头像上传组件
  const avatarUpload = document.querySelector('#avatar-upload');
  if (avatarUpload) {
    const avatarUploadComponent = new ImageUploadComponent(avatarUpload, {
      maxFiles: 1,
      type: 'avatar',
      onComplete: (files) => {
        console.log('头像上传完成:', files);
        if (files.length > 0) {
          // 更新头像显示
          const avatarImg = document.querySelector('.user-avatar');
          if (avatarImg) {
            avatarImg.src = files[0].url;
          }
        }
      }
    });
  }
});
```

---

# 📝 商品展示模块最佳实践

## 🎯 性能优化建议

### 1. **图片懒加载**
```javascript
// 使用 Intersection Observer 实现图片懒加载
const imageObserver = new IntersectionObserver((entries, observer) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target;
      img.src = img.dataset.src;
      img.classList.remove('lazy');
      observer.unobserve(img);
    }
  });
});

// 应用到商品图片
document.querySelectorAll('img[data-src]').forEach(img => {
  imageObserver.observe(img);
});
```

### 2. **无限滚动优化**
```javascript
// 防抖处理，避免频繁触发
const throttle = (func, delay) => {
  let timeoutId;
  let lastExecTime = 0;
  return function (...args) {
    const currentTime = Date.now();
    
    if (currentTime - lastExecTime > delay) {
      func.apply(this, args);
      lastExecTime = currentTime;
    } else {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => {
        func.apply(this, args);
        lastExecTime = Date.now();
      }, delay - (currentTime - lastExecTime));
    }
  };
};
```

---

# 🎉 总结

## ✅ 完善内容

本次完善为前端开发者API接口文档添加了：

### **新增接口模块**
1. **轮播图管理** - 首页广告轮播功能
2. **商品分类查询** - 多级分类导航  
3. **商品列表查询** - 分页、筛选、排序
4. **商品搜索** - 全文搜索、搜索建议
5. **商品详情查询** - 完整商品信息展示
6. **文件上传** - 图片上传、预览、压缩

### **完善的前端实现**
- 完整的JavaScript实现示例
- 性能优化（懒加载、缓存、防抖）
- 错误处理和网络监测
- 移动端适配考虑

现在前端开发者可以直接基于这个文档进行开发，实现完整的商品展示功能！

---

**📄 文档持续更新中...**  
如有问题请联系后端开发人员或查看项目Wiki。