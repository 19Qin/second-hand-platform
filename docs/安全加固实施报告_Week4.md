# 安全加固实施报告 - Week 4

## 实施日期
2025-10-01

## 实施概述
本次实施完成了二手交易平台的全面安全加固，包括分布式限流、XSS攻击防护、敏感数据加密、SQL注入防护等核心安全功能。所有功能均已通过编译验证（123个Java源文件编译成功）。

---

## 1. 分布式限流系统

### 1.1 核心组件

#### RateLimiter.java
- **位置**: `src/main/java/com/fliliy/secondhand/util/RateLimiter.java`
- **实现方式**: 基于Redis + Lua脚本的分布式限流器
- **特性**:
  - 使用Lua脚本保证原子性操作
  - 支持按用户ID、IP地址、自定义键限流
  - 自动过期机制（TTL）
  - 支持动态配置限流参数

```java
// Lua脚本核心逻辑
local current = tonumber(redis.call('get', key) or '0')
if current < maxCount then
    redis.call('incr', key)
    if current == 0 then
        redis.call('expire', key, period)
    end
    return 1
else
    return 0
end
```

#### @RateLimit注解
- **位置**: `src/main/java/com/fliliy/secondhand/annotation/RateLimit.java`
- **参数说明**:
  - `key`: 限流键前缀（默认为空，使用方法名）
  - `limitType`: 限流类型（USER/IP/CUSTOM）
  - `maxCount`: 时间窗口内最大请求数（默认100）
  - `period`: 时间窗口大小（秒，默认60）
  - `message`: 触发限流时的提示信息

#### RateLimitAspect.java
- **位置**: `src/main/java/com/fliliy/secondhand/aspect/RateLimitAspect.java`
- **功能**: AOP切面拦截，自动应用限流规则
- **工作流程**:
  1. 拦截带有@RateLimit注解的方法
  2. 根据limitType构建限流键
  3. 调用RateLimiter.tryAcquire()尝试获取令牌
  4. 限流触发则抛出RuntimeException
  5. 未触发则继续执行业务方法

### 1.2 已应用限流的接口

| 接口 | 限流规则 | 说明 |
|------|---------|------|
| `POST /api/v1/auth/sms/send` | 1次/分钟（按IP） | 防止短信轰炸 |
| `POST /api/v1/products/publish` | 5次/分钟（按用户） | 防止恶意发布 |

### 1.3 使用示例

```java
@RateLimit(
    key = "publishProduct",
    limitType = RateLimiter.LimitType.USER,
    maxCount = 5,
    period = 60,
    message = "发布商品过于频繁，请稍后再试"
)
@PostMapping("/publish")
public ApiResponse<Map<String, Object>> publishProduct(...) {
    // 业务逻辑
}
```

---

## 2. XSS攻击防护

### 2.1 核心组件

#### XssFilter.java
- **位置**: `src/main/java/com/fliliy/secondhand/filter/XssFilter.java`
- **类型**: Servlet过滤器
- **作用**: 拦截所有HTTP请求，包装为XssHttpServletRequestWrapper

#### XssHttpServletRequestWrapper.java
- **位置**: `src/main/java/com/fliliy/secondhand/filter/XssHttpServletRequestWrapper.java`
- **功能**: 重写请求包装器，自动清理XSS攻击代码

### 2.2 防护措施

#### 清理规则
1. **脚本标签清理**
   - 移除`<script>...</script>`
   - 移除`<iframe>...</iframe>`
   - 移除`<style>...</style>`

2. **危险协议清理**
   - 移除`javascript:`伪协议
   - 移除`vbscript:`伪协议

3. **危险函数清理**
   - 移除`eval(...)`
   - 移除`expression(...)`

4. **事件处理器清理**
   - 移除`onload=`、`onerror=`、`onclick=`、`onmouseover=`等事件属性

5. **HTML实体转义**
   - `<` → `&lt;`
   - `>` → `&gt;`
   - `"` → `&quot;`
   - `'` → `&#x27;`
   - `&` → `&amp;`

### 2.3 防护范围
- 所有请求参数（getParameter、getParameterValues）
- 所有请求头（getHeader）
- 自动应用，无需手动调用

---

## 3. 敏感数据加密

### 3.1 核心组件

#### EncryptionUtil.java
- **位置**: `src/main/java/com/fliliy/secondhand/util/EncryptionUtil.java`
- **加密算法**: AES-128
- **密钥管理**: 配置文件注入（`app.encryption.key`）

### 3.2 功能列表

#### 3.2.1 加密/解密
```java
// 加密
String encrypted = encryptionUtil.encrypt("敏感数据");
// 返回Base64编码的密文

// 解密
String decrypted = encryptionUtil.decrypt(encrypted);
// 返回原始明文
```

#### 3.2.2 数据脱敏

| 方法 | 输入示例 | 输出示例 | 说明 |
|------|---------|---------|------|
| `maskPhone()` | 13800138000 | 138****8000 | 手机号脱敏（保留前3后4） |
| `maskIdCard()` | 110101199001011234 | 110***********1234 | 身份证脱敏（保留前3后4） |
| `maskBankCard()` | 6222021234567890 | 6222 **** **** 7890 | 银行卡脱敏（保留前4后4） |
| `maskName()` | 张三 | 张* | 姓名脱敏（保留姓氏） |

### 3.3 配置项

```properties
# application.properties
app.encryption.key=FliliySecretKey16
```

⚠️ **安全提示**:
- 生产环境应使用强随机密钥
- 建议密钥长度≥16字节（AES-128）
- 密钥应通过环境变量或密钥管理服务注入
- 不要将密钥提交到版本控制系统

### 3.4 使用场景
- 用户隐私信息存储（身份证、银行卡）
- 日志输出时的数据脱敏
- 接口返回时的敏感信息保护
- 数据库敏感字段加密

---

## 4. SQL注入防护

### 4.1 防护措施

#### JPA参数化查询
所有Repository查询已验证使用JPA规范：
- ✅ 使用`@Query`注解 + JPQL/HQL + 命名参数（`:param`）
- ✅ 使用方法名派生查询（Spring Data自动生成）
- ✅ 使用`@Param`注解绑定参数
- ❌ 禁止使用字符串拼接构建查询

#### 示例对比

**❌ 错误示例（SQL注入风险）**
```java
@Query(value = "SELECT * FROM users WHERE username = '" + username + "'", nativeQuery = true)
User findByUsername(String username);
```

**✅ 正确示例（安全）**
```java
@Query("SELECT u FROM User u WHERE u.username = :username")
User findByUsername(@Param("username") String username);
```

### 4.2 验证结果
已检查所有Repository接口（UserRepository、ProductRepository、TransactionRepository等），确认：
- ✅ 所有查询均使用参数化形式
- ✅ 无动态SQL拼接
- ✅ 符合JPA安全规范

---

## 5. 配置更新

### application.properties新增配置

```properties
# 加密密钥
app.encryption.key=FliliySecretKey16

# Redis配置（用于限流）
spring.redis.host=localhost
spring.redis.port=6379
spring.redis.password=
spring.redis.database=0
spring.redis.timeout=10000ms
spring.redis.lettuce.pool.max-active=200
```

---

## 6. 依赖项

### 6.1 已有依赖
- Spring Boot Starter Web
- Spring Boot Starter Data JPA
- Spring Boot Starter Data Redis
- Spring Boot Starter AOP
- Apache Commons Lang3

### 6.2 无需新增依赖
所有安全功能均基于现有依赖实现，未引入新的外部库。

---

## 7. 测试验证

### 7.1 编译验证
```bash
mvn clean compile
```
**结果**: ✅ 成功编译123个Java源文件

### 7.2 功能测试建议

#### 7.2.1 限流测试
```bash
# 测试短信验证码限流（1次/分钟）
for i in {1..3}; do
  curl -X POST http://localhost:8080/api/v1/auth/sms/send \
    -H "Content-Type: application/json" \
    -d '{"mobile":"13800138000","type":"LOGIN"}'
  echo ""
done
# 预期：第2、3次请求返回"验证码发送过于频繁，请1分钟后再试"
```

#### 7.2.2 XSS防护测试
```bash
# 测试XSS攻击
curl -X POST http://localhost:8080/api/v1/products/search \
  -H "Content-Type: application/json" \
  -d '{"keyword":"<script>alert(\"XSS\")</script>手机"}'
# 预期：<script>标签被转义为&lt;script&gt;
```

#### 7.2.3 加密测试
```java
// 单元测试示例
@Test
public void testEncryption() {
    String plainText = "敏感数据123";
    String encrypted = encryptionUtil.encrypt(plainText);
    String decrypted = encryptionUtil.decrypt(encrypted);
    assertEquals(plainText, decrypted);
}

@Test
public void testMasking() {
    assertEquals("138****8000", encryptionUtil.maskPhone("13800138000"));
    assertEquals("张*", encryptionUtil.maskName("张三"));
}
```

---

## 8. 安全最佳实践

### 8.1 限流配置建议

| 接口类型 | 建议限流规则 | 说明 |
|---------|------------|------|
| 短信/邮件发送 | 1-3次/分钟（按IP或手机号） | 防止短信轰炸 |
| 登录接口 | 5-10次/分钟（按IP） | 防止暴力破解 |
| 内容发布接口 | 5-20次/分钟（按用户） | 防止垃圾信息 |
| 搜索接口 | 30-60次/分钟（按用户） | 防止爬虫 |
| 支付接口 | 3-5次/分钟（按用户） | 防止重复支付 |

### 8.2 密钥管理建议
1. **开发环境**: 使用默认密钥（已配置）
2. **测试环境**: 使用独立密钥，通过环境变量注入
3. **生产环境**: 使用密钥管理服务（如AWS KMS、阿里云KMS）
4. **密钥轮换**: 建议每季度更换一次加密密钥

### 8.3 监控建议
1. **限流监控**: 记录触发限流的请求，分析异常流量
2. **XSS监控**: 记录被过滤的XSS攻击尝试
3. **加密监控**: 监控加密/解密操作的性能

---

## 9. 已完成的安全功能

- ✅ 分布式限流系统（Redis + Lua脚本）
- ✅ @RateLimit注解 + AOP切面
- ✅ 关键接口限流配置（短信发送、商品发布）
- ✅ XSS攻击防护（Servlet过滤器）
- ✅ 敏感数据加密（AES-128）
- ✅ 数据脱敏工具（手机号、身份证、银行卡、姓名）
- ✅ SQL注入防护（JPA参数化查询）
- ✅ 编译验证通过（123个Java文件）

---

## 10. 后续优化建议

### 10.1 短期优化（Week 5-6）
1. 添加更多接口的限流配置（登录、搜索、评论等）
2. 实现限流监控仪表板
3. 添加敏感数据加密的自动化测试
4. 配置XSS白名单（允许部分HTML标签）

### 10.2 中期优化（Month 2-3）
1. 集成WAF（Web应用防火墙）
2. 实现CSRF防护
3. 添加请求签名验证
4. 实现API接口的HTTPS强制跳转

### 10.3 长期优化（Month 4+）
1. 集成专业安全扫描工具（如OWASP ZAP）
2. 实现DDoS防护
3. 添加异常登录检测（IP地理位置、设备指纹）
4. 实现数据库加密存储（TDE）

---

## 11. 技术栈总结

| 组件 | 技术选型 | 说明 |
|------|---------|------|
| 限流 | Redis + Lua | 分布式、原子性 |
| XSS防护 | Servlet Filter + Wrapper | 全局拦截 |
| 加密 | AES-128 | 对称加密，性能好 |
| SQL注入防护 | JPA + 参数化查询 | ORM层防护 |
| AOP | Spring AOP + AspectJ | 切面编程 |

---

## 12. 联系方式

如有问题或建议，请联系开发团队：
- 项目名称: Fliliy Second-Hand Platform
- 版本: 1.0.0
- 实施日期: 2025-10-01

---

**报告结束**
