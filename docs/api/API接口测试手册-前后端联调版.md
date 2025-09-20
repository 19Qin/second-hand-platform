# 📚 Fliliy 二手平台 - 统一API接口文档

> **版本**: v2.0 | **更新时间**: 2025-09-15 | **状态**: 生产就绪

## 🎯 文档导航

### 开发者文档
- [🧪 **测试手册**](#测试环境配置) - 快速测试和调试
- [📱 **Flutter开发**](./Flutter开发者API接口文档.md) - 移动端开发指南
- [💻 **前端开发**](./前端开发者API接口文档-完善版.md) - Web前端开发指南
- [🔧 **后端开发**](./后端功能开发指南.md) - 后端开发规范

---

# 🧪 API接口测试手册 [前后端联调版]

## 📋 测试环境配置

### **服务端配置**
- **开发服务器**: `http://localhost:8080`
- **API Base URL**: `http://localhost:8080/api/v1`
- **数据库**: MySQL (fliliy_db)
- **缓存**: Redis (端口6379)

### **测试工具推荐**
- **接口测试**: Postman / Insomnia / curl
- **前端调试**: Chrome DevTools
- **数据库查看**: MySQL Workbench / Navicat

---

## 🚀 快速测试流程 (5分钟验证)

### **Step 1: 启动服务**
```bash
# 进入项目目录
cd /Users/yit/Desktop/second-hand-platform2

# 启动服务
mvn spring-boot:run

# 等待看到以下日志表示启动成功:
# Started SecondHandApplication in 3.xxx seconds
```

### **Step 2: 健康检查**
```bash
curl http://localhost:8080/api/v1/health
```

**期望结果**:
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

### **Step 3: 完整用户注册登录测试**

#### 3.1 发送验证码
```bash
curl -X POST http://localhost:8080/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{
    "mobile": "13800138999",
    "type": "register"
  }'
```

**注意**: 开发环境验证码会在控制台日志中显示，格式类似：
```
2025-01-01 10:00:00.000  INFO --- [Development] SMS Code for 13800138999: 1234
```

#### 3.2 用户注册
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "测试用户001",
    "mobile": "13800138999",
    "password": "password123",
    "confirmPassword": "password123",
    "smsCode": "1234",
    "smsId": "从上一步返回的smsId",
    "agreeTerms": true
  }'
```

#### 3.3 密码登录验证
```bash
curl -X POST http://localhost:8080/api/v1/auth/login/password \
  -H "Content-Type: application/json" \
  -d '{
    "mobile": "13800138999",
    "password": "password123",
    "rememberMe": true
  }'
```

**成功后保存返回的Token用于后续测试**

---

## 📱 Postman测试集合

### **导入Postman Collection**

创建新的Collection: `Fliliy二手平台API`

#### **环境变量设置**
```json
{
  "baseUrl": "http://localhost:8080/api/v1",
  "accessToken": "",
  "refreshToken": "",
  "smsId": ""
}
```

#### **Pre-request Script (全局)**
```javascript
// 自动添加Authorization头
if (pm.environment.get("accessToken")) {
    pm.request.headers.add({
        key: "Authorization",
        value: "Bearer " + pm.environment.get("accessToken")
    });
}
```

#### **Test Script (全局)**
```javascript
// 自动保存Token
if (pm.response.json().data && pm.response.json().data.accessToken) {
    pm.environment.set("accessToken", pm.response.json().data.accessToken);
    pm.environment.set("refreshToken", pm.response.json().data.refreshToken);
}

// 自动保存smsId
if (pm.response.json().data && pm.response.json().data.smsId) {
    pm.environment.set("smsId", pm.response.json().data.smsId);
}

// 通用测试断言
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has correct structure", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('code');
    pm.expect(jsonData).to.have.property('message');
    pm.expect(jsonData).to.have.property('timestamp');
});
```

---

## 🔧 前端JavaScript测试代码

### **完整的前端测试套件**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Fliliy API 测试</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
        .success { color: green; }
        .error { color: red; }
        button { margin: 5px; padding: 10px 15px; }
        .result { background: #f5f5f5; padding: 10px; margin: 10px 0; font-family: monospace; }
    </style>
</head>
<body>
    <h1>Fliliy 二手平台 API 测试</h1>
    
    <div class="test-section">
        <h2>1. 系统健康检查</h2>
        <button onclick="testHealth()">测试 /health</button>
        <div id="healthResult" class="result"></div>
    </div>
    
    <div class="test-section">
        <h2>2. 用户认证测试</h2>
        <input type="text" id="testMobile" placeholder="手机号" value="13800138999">
        <input type="text" id="testUsername" placeholder="用户名" value="测试用户001">
        <input type="password" id="testPassword" placeholder="密码" value="password123">
        <br><br>
        <button onclick="testSendSms()">发送验证码</button>
        <button onclick="testRegister()">注册</button>
        <button onclick="testLogin()">登录</button>
        <button onclick="testValidateToken()">验证Token</button>
        <button onclick="testRefreshToken()">刷新Token</button>
        <button onclick="testLogout()">退出</button>
        <div id="authResult" class="result"></div>
    </div>
    
    <div class="test-section">
        <h2>3. 测试日志</h2>
        <div id="testLog" class="result" style="height: 300px; overflow-y: scroll;"></div>
        <button onclick="clearLog()">清空日志</button>
    </div>

    <script>
        // 全局配置
        const API_BASE_URL = 'http://localhost:8080/api/v1';
        let currentTokens = {
            accessToken: localStorage.getItem('accessToken') || '',
            refreshToken: localStorage.getItem('refreshToken') || '',
            smsId: ''
        };

        // 统一API请求方法
        async function apiRequest(endpoint, options = {}) {
            const url = `${API_BASE_URL}${endpoint}`;
            
            const config = {
                headers: {
                    'Content-Type': 'application/json',
                    ...(currentTokens.accessToken && {
                        'Authorization': `Bearer ${currentTokens.accessToken}`
                    })
                },
                ...options
            };
            
            log(`请求: ${options.method || 'GET'} ${url}`);
            if (options.body) {
                log(`请求体: ${options.body}`);
            }
            
            try {
                const response = await fetch(url, config);
                const result = await response.json();
                
                log(`响应 (${response.status}): ${JSON.stringify(result, null, 2)}`);
                
                // 自动保存Token
                if (result.data && result.data.accessToken) {
                    currentTokens.accessToken = result.data.accessToken;
                    currentTokens.refreshToken = result.data.refreshToken;
                    localStorage.setItem('accessToken', currentTokens.accessToken);
                    localStorage.setItem('refreshToken', currentTokens.refreshToken);
                }
                
                // 自动保存smsId
                if (result.data && result.data.smsId) {
                    currentTokens.smsId = result.data.smsId;
                }
                
                return result;
                
            } catch (error) {
                log(`请求失败: ${error.message}`, 'error');
                throw error;
            }
        }

        // 日志记录
        function log(message, type = 'info') {
            const logDiv = document.getElementById('testLog');
            const timestamp = new Date().toLocaleTimeString();
            const className = type === 'error' ? 'error' : type === 'success' ? 'success' : '';
            
            logDiv.innerHTML += `<div class="${className}">[${timestamp}] ${message}</div>`;
            logDiv.scrollTop = logDiv.scrollHeight;
        }

        function clearLog() {
            document.getElementById('testLog').innerHTML = '';
        }

        // 显示结果
        function showResult(elementId, result, isSuccess = true) {
            const element = document.getElementById(elementId);
            element.innerHTML = `<pre>${JSON.stringify(result, null, 2)}</pre>`;
            element.className = `result ${isSuccess ? 'success' : 'error'}`;
        }

        // 测试方法
        async function testHealth() {
            try {
                const result = await apiRequest('/health');
                showResult('healthResult', result);
                log('健康检查通过', 'success');
            } catch (error) {
                showResult('healthResult', {error: error.message}, false);
                log(`健康检查失败: ${error.message}`, 'error');
            }
        }

        async function testSendSms() {
            const mobile = document.getElementById('testMobile').value;
            try {
                const result = await apiRequest('/auth/sms/send', {
                    method: 'POST',
                    body: JSON.stringify({
                        mobile,
                        type: 'register'
                    })
                });
                showResult('authResult', result);
                log('验证码发送成功，请在控制台查看验证码', 'success');
            } catch (error) {
                showResult('authResult', {error: error.message}, false);
            }
        }

        async function testRegister() {
            const mobile = document.getElementById('testMobile').value;
            const username = document.getElementById('testUsername').value;
            const password = document.getElementById('testPassword').value;
            
            // 模拟验证码，实际应该从控制台获取
            const smsCode = prompt('请输入验证码（从服务器控制台复制）:');
            if (!smsCode || !currentTokens.smsId) {
                log('请先发送验证码', 'error');
                return;
            }
            
            try {
                const result = await apiRequest('/auth/register', {
                    method: 'POST',
                    body: JSON.stringify({
                        username,
                        mobile,
                        password,
                        confirmPassword: password,
                        smsCode,
                        smsId: currentTokens.smsId,
                        agreeTerms: true
                    })
                });
                showResult('authResult', result);
                log('用户注册成功', 'success');
            } catch (error) {
                showResult('authResult', {error: error.message}, false);
            }
        }

        async function testLogin() {
            const mobile = document.getElementById('testMobile').value;
            const password = document.getElementById('testPassword').value;
            
            try {
                const result = await apiRequest('/auth/login/password', {
                    method: 'POST',
                    body: JSON.stringify({
                        mobile,
                        password,
                        rememberMe: true
                    })
                });
                showResult('authResult', result);
                log('登录成功', 'success');
            } catch (error) {
                showResult('authResult', {error: error.message}, false);
            }
        }

        async function testValidateToken() {
            if (!currentTokens.accessToken) {
                log('请先登录获取Token', 'error');
                return;
            }
            
            try {
                const result = await apiRequest('/auth/validate');
                showResult('authResult', result);
                log('Token验证通过', 'success');
            } catch (error) {
                showResult('authResult', {error: error.message}, false);
            }
        }

        async function testRefreshToken() {
            if (!currentTokens.refreshToken) {
                log('请先登录获取RefreshToken', 'error');
                return;
            }
            
            try {
                const result = await apiRequest('/auth/token/refresh', {
                    method: 'POST',
                    body: JSON.stringify({
                        refreshToken: currentTokens.refreshToken
                    })
                });
                showResult('authResult', result);
                log('Token刷新成功', 'success');
            } catch (error) {
                showResult('authResult', {error: error.message}, false);
            }
        }

        async function testLogout() {
            try {
                const result = await apiRequest('/auth/logout', {
                    method: 'POST',
                    body: JSON.stringify({
                        refreshToken: currentTokens.refreshToken
                    })
                });
                
                // 清空本地Token
                currentTokens = {accessToken: '', refreshToken: '', smsId: ''};
                localStorage.removeItem('accessToken');
                localStorage.removeItem('refreshToken');
                
                showResult('authResult', result);
                log('退出登录成功', 'success');
            } catch (error) {
                showResult('authResult', {error: error.message}, false);
            }
        }

        // 页面加载时的初始化
        window.onload = function() {
            log('API测试页面已加载');
            log(`当前Token状态: ${currentTokens.accessToken ? '已登录' : '未登录'}`);
            
            // 自动测试健康检查
            testHealth();
        };
    </script>
</body>
</html>
```

---

## 🐛 常见错误排查指南

### **错误1: 连接被拒绝**
```
Error: connect ECONNREFUSED 127.0.0.1:8080
```
**解决方案**:
- 检查后端服务是否启动
- 确认端口号是否正确 (8080)
- 检查防火墙设置

### **错误2: 跨域问题**
```
Access to fetch at 'http://localhost:8080/api/v1/health' from origin 'null' has been blocked by CORS policy
```
**解决方案**:
- 后端已配置CORS，如果仍有问题，请检查请求头
- 使用正确的Content-Type: application/json

### **错误3: Token格式错误**
```json
{
  "code": 401,
  "message": "Authorization header is missing or invalid"
}
```
**解决方案**:
- 检查Authorization头格式: `Bearer {token}`
- 确认Token没有多余的空格或换行符

### **错误4: 验证码过期**
```json
{
  "code": 1004,
  "message": "验证码已过期"
}
```
**解决方案**:
- 重新获取验证码
- 确认在5分钟内使用验证码

### **错误5: 数据库连接失败**
```
com.mysql.cj.jdbc.exceptions.CommunicationsException: Communications link failure
```
**解决方案**:
- 检查MySQL服务是否运行
- 确认数据库配置正确
- 检查用户名密码

---

## 📊 测试数据准备

### **测试用户数据**
```sql
-- 查看现有测试用户
SELECT id, username, mobile, created_at FROM users WHERE mobile LIKE '138%';

-- 清理测试数据（谨慎使用）
DELETE FROM users WHERE mobile = '13800138999';
DELETE FROM verification_codes WHERE mobile = '13800138999';
DELETE FROM sms_records WHERE mobile = '13800138999';
```

### **验证码测试**
```sql
-- 查看验证码记录
SELECT * FROM verification_codes WHERE mobile = '13800138999' ORDER BY created_at DESC LIMIT 5;

-- 查看短信发送记录
SELECT * FROM sms_records WHERE mobile = '13800138999' ORDER BY created_at DESC LIMIT 5;
```

---

## 🚀 性能测试

### **并发测试脚本**
```bash
#!/bin/bash

# 并发发送验证码测试
for i in {1..10}
do
   curl -X POST http://localhost:8080/api/v1/auth/sms/send \
     -H "Content-Type: application/json" \
     -d "{\"mobile\": \"1380013800${i}\", \"type\": \"register\"}" &
done

wait
echo "并发测试完成"
```

### **压力测试建议**
- 使用Apache Bench (ab) 进行压力测试
- 监控数据库连接数
- 观察Redis内存使用情况
- 检查日志中的错误信息

---

## 📝 测试报告模板

### **功能测试报告**
```markdown
# 接口测试报告

## 测试环境
- 服务器: localhost:8080
- 数据库: MySQL 8.0.16
- 缓存: Redis 5.0.10

## 测试结果
| 接口 | 测试状态 | 响应时间 | 备注 |
|------|----------|----------|------|
| /health | ✅ 通过 | 15ms | 正常 |
| /auth/sms/send | ✅ 通过 | 45ms | 验证码正常发送 |
| /auth/register | ✅ 通过 | 120ms | 注册成功 |
| /auth/login/password | ✅ 通过 | 80ms | 登录正常 |

## 发现问题
1. 无

## 建议
1. 建议添加接口限流
2. 考虑添加接口缓存
```

---

**🔧 文档更新时间**: 2025-09-02  
**📧 问题反馈**: 请联系后端开发团队  
**📖 更多文档**: 查看项目Wiki