# 🚀 Fliliy 二手交易平台

## 📖 项目概述

Fliliy是一个现代化的二手交易平台，支持商品发布、实时聊天、收藏管理等功能。

**版本**: v2.0  
**更新时间**: 2025-09-15  
**开发状态**: 生产就绪

## 🏗️ 技术架构

### 后端技术栈
- **框架**: Spring Boot 2.7+
- **数据库**: MySQL 8.0 + Redis
- **安全**: Spring Security + JWT
- **实时通信**: WebSocket
- **文件存储**: 本地存储 + CDN

### 前端技术栈
- **Web**: React/Vue.js + TypeScript
- **移动端**: Flutter
- **状态管理**: Redux/Vuex/GetX

## 📚 文档导航

### 开发文档
- [`API接口文档`](./docs/api/API接口测试手册-前后端联调版.md) - 完整的API接口说明
- [`数据库设计`](./docs/database/合并优化后数据库设计.sql) - 数据库结构和关系
- [`开发指南`](./docs/deployment/后端功能开发指南.md) - 后端开发规范

### 特定平台文档
- [`Flutter开发文档`](./docs/api/Flutter开发者API接口文档.md) - Flutter应用开发
- [`前端开发文档`](./docs/api/前端开发者API接口文档-完善版.md) - Web前端开发

### 部署和测试
- [`聊天系统部署`](./docs/deployment/聊天系统部署指南.md) - WebSocket部署指南
- [`测试脚本`](./docs/testing/) - 测试脚本集合

## 🚀 快速开始

### 1. 环境要求
- Java 8+
- MySQL 8.0+
- Redis 5.0+
- Maven 3.6+

### 2. 项目启动
```bash
# 克隆项目
git clone [repository-url]

# 进入目录
cd second-hand-platform2

# 编译运行
mvn spring-boot:run

# 或使用快速测试脚本
./quick-compile-test.sh
```

### 3. 访问地址
- **API Base URL**: http://localhost:8080/api/v1
- **健康检查**: http://localhost:8080/api/v1/health
- **WebSocket测试页**: http://localhost:8080/websocket-chat-client.html

## 🔧 核心功能

### 用户认证
- ✅ 手机验证码注册/登录
- ✅ JWT Token管理
- ✅ 自动刷新机制

### 商品管理
- ✅ 商品发布与编辑
- ✅ 图片上传
- ✅ 分类筛选
- ✅ 收藏功能

### 实时聊天
- ✅ WebSocket实时通信
- ✅ 聊天室管理
- ✅ 消息历史记录

### 系统功能
- ✅ 分页查询
- ✅ 缓存机制
- ✅ 异常处理
- ✅ 日志记录

## 📱 API接口概览

### 认证模块
```
POST   /auth/login/password     # 密码登录
POST   /auth/register          # 用户注册
POST   /auth/sms/send          # 发送验证码
POST   /auth/refresh           # 刷新Token
```

### 商品模块
```
GET    /products              # 商品列表
GET    /products/{id}         # 商品详情
POST   /products              # 发布商品
POST   /products/{id}/favorite # 收藏商品
```

### 聊天模块
```
GET    /chats                 # 聊天列表
POST   /chats/rooms           # 创建聊天室
POST   /chats/{id}/messages   # 发送消息
```

## 🗄️ 数据库设计

主要数据表：
- `users` - 用户信息
- `products` - 商品信息
- `categories` - 商品分类
- `chat_rooms` - 聊天室
- `chat_messages` - 聊天消息
- `product_favorites` - 商品收藏

详细设计请查看：[数据库设计文档](./docs/database/合并优化后数据库设计.sql)

## 🧪 测试说明

### 快速测试
```bash
# 健康检查
curl http://localhost:8080/api/v1/health

# 用户注册流程测试
./test_chat_api.sh

# WebSocket功能测试
./test-websocket.sh
```

### 测试数据
项目包含预置测试数据，包括：
- 测试用户账号
- 商品分类数据
- 示例商品信息

## 📈 项目状态

### 已完成功能
- [x] 用户认证系统
- [x] 商品管理系统
- [x] 实时聊天功能
- [x] 文件上传功能
- [x] 基础API接口

### 计划中功能
- [ ] 支付系统集成
- [ ] 推送通知
- [ ] 高级搜索
- [ ] 数据统计分析

详细进度请查看：[项目进度记录](./docs/项目进度记录.md)

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详情请查看 [LICENSE](LICENSE) 文件

## 📞 联系我们

- 项目维护者：开发团队
- 问题反馈：通过 GitHub Issues
- 技术讨论：项目 Wiki

---

**最后更新**: 2025-09-15  
**文档版本**: v2.0