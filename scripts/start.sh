#!/bin/bash

# ============================================
# Fliliy二手平台 - Docker一键启动脚本
# ============================================

set -e

echo "============================================"
echo "🚀 启动Fliliy二手平台..."
echo "============================================"
echo ""

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker Desktop"
    exit 1
fi

# 进入项目目录
cd "$(dirname "$0")/.."

# 停止旧容器（如果存在）
echo "📦 停止旧容器..."
docker-compose down 2>/dev/null || true
echo ""

# 清理悬空镜像（可选）
echo "🧹 清理悬空镜像..."
docker image prune -f
echo ""

# 构建镜像
echo "🔨 构建应用镜像..."
docker-compose build --no-cache
echo ""

# 启动所有服务
echo "🚀 启动所有服务..."
docker-compose up -d
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10
echo ""

# 查看服务状态
echo "📊 服务状态:"
docker-compose ps
echo ""

# 检查服务健康状态
echo "🏥 健康检查:"
echo ""

# 检查MySQL
echo -n "  MySQL: "
if docker exec fliliy-mysql mysqladmin ping -h localhost -uroot -proot123 --silent 2>/dev/null; then
    echo "✅ 运行正常"
else
    echo "⚠️  启动中..."
fi

# 检查Redis
echo -n "  Redis: "
if docker exec fliliy-redis redis-cli -a redis123 ping 2>/dev/null | grep -q PONG; then
    echo "✅ 运行正常"
else
    echo "⚠️  启动中..."
fi

# 检查Elasticsearch
echo -n "  Elasticsearch: "
if curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -q "green\|yellow"; then
    echo "✅ 运行正常"
else
    echo "⚠️  启动中..."
fi

# 检查RabbitMQ
echo -n "  RabbitMQ: "
if docker exec fliliy-rabbitmq rabbitmq-diagnostics ping 2>/dev/null | grep -q "Ping succeeded"; then
    echo "✅ 运行正常"
else
    echo "⚠️  启动中..."
fi

# 等待应用启动
echo -n "  应用服务: "
for i in {1..30}; do
    if curl -s http://localhost:8080/actuator/health 2>/dev/null | grep -q "UP"; then
        echo "✅ 运行正常"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "⚠️  启动超时，请检查日志"
    else
        sleep 2
    fi
done

echo ""
echo "============================================"
echo "✅ 启动完成！"
echo "============================================"
echo ""
echo "📱 访问地址:"
echo "  应用服务:   http://localhost:8080"
echo "  健康检查:   http://localhost:8080/actuator/health"
echo "  API文档:    http://localhost:8080/doc.html"
echo "  Kibana:     http://localhost:5601"
echo "  RabbitMQ:   http://localhost:15672 (admin/admin123)"
echo ""
echo "💡 常用命令:"
echo "  查看日志:   ./scripts/logs.sh"
echo "  停止服务:   ./scripts/stop.sh"
echo "  重启服务:   ./scripts/restart.sh"
echo "  查看状态:   docker-compose ps"
echo ""
