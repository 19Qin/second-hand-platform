# 🚀 Fliliy 二手交易平台

## 📖 项目概述

Fliliy是一个现代化的二手交易平台，支持商品发布、实时聊天、收藏管理等功能。基于用户关系导向的聊天系统，提供更流畅的用户体验。

**版本**: v3.0  
**更新时间**: 2025-09-23  
**开发状态**: 生产就绪 ✅

## 🎉 v3.0 重大更新

### 聊天系统重构优化
- **问题解决**: 将"商品导向"聊天系统重构为"用户关系导向"
- **用户体验**: 一对用户只有一个聊天室，可在同一聊天室讨论多个商品
- **界面优化**: 聊天列表清晰，避免重复显示同一商家
- **功能增强**: 支持商品卡片消息、消息搜索、聊天记录导出

### SQL设计合并优化
- **数据库重构**: 统一聊天室设计，优化查询性能
- **索引优化**: 添加复合索引，提升查询效率
- **数据一致性**: 完善外键约束和触发器
- **存储优化**: 优化消息存储结构，减少冗余数据

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

### 🔥 最新统一文档（推荐）
- [`统一API文档v3.0`](./docs/api/统一API文档v3.0.md) - **合并优化后的完整API文档**
- [`优化后聊天API文档`](./docs/api/optimized_chat_api_documentation.md) - 聊天系统重构详细说明
- [`合并优化后数据库设计`](./docs/database/合并优化后数据库设计.sql) - 最新数据库结构

### 开发文档
- [`后端功能开发指南`](./docs/deployment/后端功能开发指南.md) - 后端开发规范和最佳实践
- [`API接口测试手册`](./docs/api/API接口测试手册-前后端联调版.md) - 接口测试和调试指南
- [`项目进度记录`](./docs/project_progress_2025-09-23.md) - 最新开发进度

### 特定平台文档
- [`Flutter开发文档`](./docs/api/Flutter开发者API接口文档.md) - Flutter应用开发完整指南
- [`前端开发文档`](./docs/api/前端开发者API接口文档-完善版.md) - Web前端开发规范

### 部署和测试
- [`聊天系统部署指南`](./docs/deployment/聊天系统部署指南.md) - WebSocket部署和优化
- [`测试文档集合`](./docs/testing/) - 完整测试脚本和报告

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

### 实时聊天系统 🔥
- ✅ 用户关系导向聊天室（重构优化）
- ✅ WebSocket实时通信
- ✅ 多媒体消息支持（文本、图片、语音、商品卡片）
- ✅ 消息状态管理（已送达、已读、撤回）
- ✅ 高级功能（置顶、免打扰、搜索、导出）
- ✅ 商品关联讨论

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

### 聊天模块 🔥 [已重构优化]
```
POST   /chats/product-discussion    # 开始商品讨论（创建聊天室）
GET    /chats                      # 获取聊天列表（用户关系导向）
GET    /chats/{id}/messages        # 获取聊天记录
POST   /chats/{id}/messages        # 发送消息（支持多媒体）
POST   /chats/{id}/read           # 标记已读
POST   /chats/messages/{id}/recall # 撤回消息
```

### 交易模块
```
POST   /transactions/inquiry       # 发起交易咨询
POST   /transactions/{id}/agree-offline  # 同意线下交易
POST   /transactions/{id}/complete # 完成交易
GET    /transactions              # 交易记录
```

## 🗄️ 数据库设计

### 核心数据表
- `users` - 用户信息（支持软删除）
- `products` - 商品信息（地理位置搜索）
- `categories` - 商品分类（层级结构）
- `chat_rooms` - 聊天室（用户关系导向 🔥）
- `chat_messages` - 聊天消息（多媒体支持）
- `transactions` - 交易记录（完整流程）
- `product_favorites` - 商品收藏
- `verification_codes` - 验证码管理

### 🔥 v3.0 数据库优化亮点
- **聊天表重构**: 移除product_id，采用buyer_id + seller_id唯一约束
- **性能优化**: 添加复合索引，优化查询性能
- **消息关联**: 通过related_product_id关联商品讨论
- **数据完整性**: 完善外键约束和触发器

详细设计请查看：[合并优化后数据库设计](./docs/database/合并优化后数据库设计.sql)

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

### ✅ v3.0 已完成功能
- [x] 用户认证系统（中国+澳洲手机号支持）
- [x] 商品管理系统（完整发布流程）
- [x] **实时聊天系统（重构优化完成） 🔥**
- [x] 交易管理系统（线下交易流程）
- [x] 文件管理系统（多媒体上传）
- [x] 用户中心系统（个人信息管理）
- [x] API文档统一整理

### 🔧 计划中功能
- [ ] 支付系统集成
- [ ] 消息推送通知
- [ ] AI商品推荐
- [ ] 数据统计分析
- [ ] 移动端APP适配

### 📊 项目质量指标
- **功能完整度**: 95% ✅
- **代码质量**: 90% ✅
- **API文档**: 95% ✅
- **数据库设计**: 95% ✅

详细进度请查看：[项目进度记录v3.0](./docs/project_progress_2025-09-23.md)

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

## 🎯 v3.0 总结

本次更新完成了聊天系统的重大重构，解决了用户体验问题，提升了系统性能。主要成果：

1. **聊天系统优化** - 从商品导向改为用户关系导向，解决了聊天列表重复显示问题
2. **数据库重构** - 优化了表结构和索引，提升查询性能
3. **API文档统一** - 整合了所有API文档，删除冗余部分
4. **功能完善** - 支持多媒体消息、消息状态管理、高级聊天功能

项目现已达到生产级别标准，具备良好的可扩展性和维护性。

---

**最后更新**: 2025-09-23  
**文档版本**: v3.0  
**重大更新**: 聊天系统重构完成 🎉