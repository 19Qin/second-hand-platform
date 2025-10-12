# 🚀 Docker快速启动指南

> **5分钟快速上手Fliliy二手平台Docker部署**

---

## ⚡ 超快速启动（3步）

```bash
# 1. 进入项目目录
cd /Users/yit/Desktop/second-hand-platform2

# 2. 一键启动所有服务
./scripts/start.sh

# 3. 验证服务
curl http://localhost:8080/actuator/health
```

---

## 🎯 访问地址

启动成功后立即访问：

| 服务 | 地址 | 用户名/密码 |
|-----|------|-----------|
| **应用API** | http://localhost:8080 | - |
| **健康检查** | http://localhost:8080/actuator/health | - |
| **Swagger文档** | http://localhost:8080/doc.html | - |
| **Kibana** | http://localhost:5601 | - |
| **RabbitMQ管理** | http://localhost:15672 | admin/admin123 |

---

## 📜 常用命令

```bash
# 查看服务状态
./scripts/status.sh

# 查看日志
./scripts/logs.sh

# 重启服务
./scripts/restart.sh

# 停止服务
./scripts/stop.sh

# 完全清理（包括数据）
./scripts/clean.sh
```

---

## 🔧 开发模式

只启动MySQL、Redis、ES等依赖服务，应用在IDE中运行：

```bash
# 启动依赖服务
docker-compose -f docker-compose.dev.yml up -d

# 在IDE中运行应用
mvn spring-boot:run
```

---

## ❓ 常见问题

### 端口被占用

```bash
# 查看端口占用
lsof -i :8080

# 停止占用端口的进程
kill -9 <PID>
```

### 服务启动失败

```bash
# 查看详细日志
./scripts/logs.sh

# 选择对应的服务查看日志
```

### 数据库初始化

```bash
# 手动导入SQL
docker exec -i fliliy-mysql mysql -uroot -proot123 fliliy_db < docs/database/合并优化后数据库设计.sql
```

---

## 📚 详细文档

- **完整部署指南**: [scripts/README.md](scripts/README.md)
- **部署完成报告**: [docs/Docker容器化部署完成报告_2025-10-02.md](docs/Docker容器化部署完成报告_2025-10-02.md)
- **技术路线图**: [docs/技术开发路线图_v5.0.md](docs/技术开发路线图_v5.0.md)

---

**最后更新**: 2025-10-02
