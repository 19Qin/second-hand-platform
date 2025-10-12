# 🐳 Fliliy二手平台 - Docker部署指南

## 📋 目录

- [快速开始](#快速开始)
- [脚本说明](#脚本说明)
- [环境说明](#环境说明)
- [常见问题](#常见问题)
- [高级配置](#高级配置)

---

## 🚀 快速开始

### 前置要求

- Docker Desktop 20.10+
- Docker Compose 2.0+
- 至少4GB可用内存
- 至少10GB可用磁盘空间

### 一键启动

```bash
# 启动所有服务
./scripts/start.sh

# 或者手动启动
docker-compose up -d
```

### 访问地址

启动成功后，访问以下地址：

| 服务 | 地址 | 说明 |
|-----|------|------|
| **应用服务** | http://localhost:8080 | 主应用 |
| **健康检查** | http://localhost:8080/actuator/health | 监控端点 |
| **API文档** | http://localhost:8080/doc.html | Swagger文档 |
| **Kibana** | http://localhost:5601 | ES可视化 |
| **RabbitMQ** | http://localhost:15672 | 消息队列管理 (admin/admin123) |

---

## 📜 脚本说明

### 核心脚本

| 脚本 | 功能 | 使用方法 |
|-----|------|---------|
| `start.sh` | 启动所有服务 | `./scripts/start.sh` |
| `stop.sh` | 停止所有服务 | `./scripts/stop.sh` |
| `restart.sh` | 重启所有服务 | `./scripts/restart.sh` |
| `logs.sh` | 查看日志 | `./scripts/logs.sh` |
| `status.sh` | 查看状态 | `./scripts/status.sh` |
| `clean.sh` | 清理所有资源 | `./scripts/clean.sh` |

### 使用示例

```bash
# 1. 启动服务
./scripts/start.sh

# 2. 查看状态
./scripts/status.sh

# 3. 查看应用日志
./scripts/logs.sh
# 然后选择 1 (应用服务)

# 4. 重启服务
./scripts/restart.sh

# 5. 停止服务
./scripts/stop.sh

# 6. 完全清理（包括数据）
./scripts/clean.sh
```

---

## 🌍 环境说明

### 生产环境（默认）

使用 `docker-compose.yml`，包含完整的服务栈：

```bash
docker-compose up -d
```

服务列表：
- ✅ Spring Boot应用
- ✅ MySQL 8.0
- ✅ Redis 7
- ✅ Elasticsearch 7.17.10
- ✅ Kibana
- ✅ RabbitMQ 3.12

### 开发环境

使用 `docker-compose.dev.yml`，仅启动依赖服务：

```bash
# 仅启动MySQL、Redis、ES、RabbitMQ
docker-compose -f docker-compose.dev.yml up -d

# 应用在IDE中运行，连接到上述服务
mvn spring-boot:run
```

---

## 📦 服务详情

### MySQL数据库

- **端口**: 3306
- **用户**: fliliy / fliliy123
- **数据库**: fliliy_db
- **Root密码**: root123

连接命令：
```bash
docker exec -it fliliy-mysql mysql -ufliliy -pfliliy123 fliliy_db
```

### Redis缓存

- **端口**: 6379
- **密码**: redis123

连接命令：
```bash
docker exec -it fliliy-redis redis-cli -a redis123
```

### Elasticsearch

- **HTTP端口**: 9200
- **集群端口**: 9300
- **无密码**

测试命令：
```bash
curl http://localhost:9200
curl http://localhost:9200/products/_search
```

### RabbitMQ

- **AMQP端口**: 5672
- **管理界面**: 15672
- **用户**: admin / admin123

管理界面：http://localhost:15672

---

## ❓ 常见问题

### 1. 端口被占用

**问题**: 启动失败，提示端口已被占用

**解决**:
```bash
# 查看端口占用
lsof -i :8080
lsof -i :3306

# 停止占用端口的进程或修改docker-compose.yml中的端口映射
# 例如将8080改为8081
ports:
  - "8081:8080"
```

### 2. 内存不足

**问题**: 服务启动失败或频繁重启

**解决**:
```bash
# 减少Elasticsearch内存
# 修改docker-compose.yml中的ES_JAVA_OPTS
- "ES_JAVA_OPTS=-Xms256m -Xmx256m"

# 减少应用内存
# 修改JAVA_OPTS
JAVA_OPTS: -Xms256m -Xmx512m -XX:+UseG1GC
```

### 3. 数据库初始化失败

**问题**: MySQL启动后没有数据表

**解决**:
```bash
# 手动导入SQL文件
docker exec -i fliliy-mysql mysql -uroot -proot123 fliliy_db < docs/database/合并优化后数据库设计.sql
```

### 4. Elasticsearch黄色状态

**问题**: ES集群健康状态为yellow

**解决**: 这是正常的，单节点ES默认为yellow（副本未分配）。不影响使用。

### 5. 应用启动慢

**问题**: 应用容器启动时间超过2分钟

**原因**:
- Maven依赖下载慢
- 应用初始化耗时

**解决**:
```bash
# 1. 使用阿里云Maven镜像（修改pom.xml）
# 2. 增加启动超时时间（修改healthcheck的start_period）
# 3. 查看启动日志
docker logs -f fliliy-app
```

---

## 🔧 高级配置

### 数据持久化

数据卷位置：
```
fliliy-mysql-data    -> /var/lib/docker/volumes/fliliy-mysql-data
fliliy-redis-data    -> /var/lib/docker/volumes/fliliy-redis-data
fliliy-es-data       -> /var/lib/docker/volumes/fliliy-es-data
fliliy-rabbitmq-data -> /var/lib/docker/volumes/fliliy-rabbitmq-data
```

备份数据：
```bash
# 备份MySQL
docker exec fliliy-mysql mysqldump -uroot -proot123 fliliy_db > backup.sql

# 恢复MySQL
docker exec -i fliliy-mysql mysql -uroot -proot123 fliliy_db < backup.sql
```

### 自定义配置

1. **修改环境变量**

编辑 `docker-compose.yml`，修改environment部分：

```yaml
environment:
  SPRING_DATASOURCE_PASSWORD: your_password
  SPRING_REDIS_PASSWORD: your_redis_password
```

2. **挂载配置文件**

```yaml
volumes:
  - ./config/application-prod.yml:/app/config/application.yml
```

3. **使用.env文件**

创建 `.env` 文件：
```properties
MYSQL_ROOT_PASSWORD=your_password
REDIS_PASSWORD=your_password
```

### 性能优化

1. **MySQL优化**
```yaml
command:
  - --innodb_buffer_pool_size=1G
  - --max_connections=1000
```

2. **Redis优化**
```yaml
command: redis-server --maxmemory 1gb --maxmemory-policy allkeys-lru
```

3. **Elasticsearch优化**
```yaml
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
  - bootstrap.memory_lock=true
```

### 多环境部署

```bash
# 开发环境
docker-compose -f docker-compose.dev.yml up -d

# 生产环境
docker-compose -f docker-compose.yml up -d

# 测试环境
docker-compose -f docker-compose.test.yml up -d
```

---

## 📊 监控和调试

### 查看容器资源使用

```bash
# 实时监控
docker stats

# 查看特定容器
docker stats fliliy-app
```

### 进入容器

```bash
# 进入应用容器
docker exec -it fliliy-app sh

# 进入MySQL容器
docker exec -it fliliy-mysql bash

# 进入Redis容器
docker exec -it fliliy-redis sh
```

### 查看日志

```bash
# 查看应用日志（最近100行）
docker logs --tail 100 fliliy-app

# 实时跟踪日志
docker logs -f fliliy-app

# 查看所有服务日志
docker-compose logs -f
```

### 健康检查

```bash
# 应用健康检查
curl http://localhost:8080/actuator/health

# MySQL健康检查
docker exec fliliy-mysql mysqladmin ping -h localhost -uroot -proot123

# Redis健康检查
docker exec fliliy-redis redis-cli -a redis123 ping

# ES健康检查
curl http://localhost:9200/_cluster/health
```

---

## 🎯 最佳实践

### 开发流程

1. **本地开发**
```bash
# 启动依赖服务
docker-compose -f docker-compose.dev.yml up -d

# 在IDE中运行应用
mvn spring-boot:run
```

2. **测试部署**
```bash
# 构建并启动所有服务
./scripts/start.sh

# 运行测试
curl http://localhost:8080/actuator/health
```

3. **生产部署**
```bash
# 使用生产配置
docker-compose up -d

# 检查服务状态
./scripts/status.sh

# 监控日志
./scripts/logs.sh
```

### 版本管理

```bash
# 标记镜像版本
docker tag fliliy/second-hand-platform:3.0 fliliy/second-hand-platform:3.0.1

# 推送到仓库
docker push fliliy/second-hand-platform:3.0.1

# 使用特定版本
docker pull fliliy/second-hand-platform:3.0.1
```

---

## 📞 获取帮助

- **查看日志**: `./scripts/logs.sh`
- **检查状态**: `./scripts/status.sh`
- **查看文档**: `docs/`目录
- **技术路线图**: `docs/技术开发路线图_v5.0.md`

---

**最后更新**: 2025-10-02
**Docker版本**: 3.0
**文档版本**: v1.0
