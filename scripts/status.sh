#!/bin/bash

# ============================================
# Fliliy二手平台 - 状态检查脚本
# ============================================

# 进入项目目录
cd "$(dirname "$0")/.."

echo "============================================"
echo "📊 Fliliy二手平台状态检查"
echo "============================================"
echo ""

# 检查容器状态
echo "📦 容器状态:"
docker-compose ps
echo ""

# 详细健康检查
echo "🏥 详细健康检查:"
echo ""

# MySQL
echo -n "  MySQL (3306): "
if docker exec fliliy-mysql mysqladmin ping -h localhost -uroot -proot123 --silent 2>/dev/null; then
    echo "✅ 运行正常"
    docker exec fliliy-mysql mysql -uroot -proot123 -e "SELECT COUNT(*) as 'Tables' FROM information_schema.tables WHERE table_schema='fliliy_db';" 2>/dev/null | tail -n 1 | xargs echo "    数据表数量:"
else
    echo "❌ 未运行"
fi

# Redis
echo -n "  Redis (6379): "
if docker exec fliliy-redis redis-cli -a redis123 ping 2>/dev/null | grep -q PONG; then
    echo "✅ 运行正常"
    docker exec fliliy-redis redis-cli -a redis123 dbsize 2>/dev/null | xargs echo "    缓存键数量:"
else
    echo "❌ 未运行"
fi

# Elasticsearch
echo -n "  Elasticsearch (9200): "
if curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -q "green\|yellow"; then
    echo "✅ 运行正常"
    curl -s http://localhost:9200/_cat/indices?v 2>/dev/null | grep products | awk '{print "    商品索引: "$3" 文档"}'
else
    echo "❌ 未运行"
fi

# RabbitMQ
echo -n "  RabbitMQ (5672): "
if docker exec fliliy-rabbitmq rabbitmq-diagnostics ping 2>/dev/null | grep -q "Ping succeeded"; then
    echo "✅ 运行正常"
else
    echo "❌ 未运行"
fi

# 应用服务
echo -n "  应用服务 (8080): "
if curl -s http://localhost:8080/actuator/health 2>/dev/null | grep -q "UP"; then
    echo "✅ 运行正常"
    echo "    健康检查: http://localhost:8080/actuator/health"
else
    echo "❌ 未运行或启动中"
fi

echo ""

# 资源使用情况
echo "💻 资源使用情况:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep fliliy
echo ""

# 网络信息
echo "🌐 网络信息:"
docker network inspect fliliy-network --format '{{range .Containers}}  {{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

# 数据卷信息
echo "💾 数据卷信息:"
docker volume ls | grep fliliy
echo ""

echo "============================================"
echo "💡 提示:"
echo "  查看日志: ./scripts/logs.sh"
echo "  重启服务: ./scripts/restart.sh"
echo "  停止服务: ./scripts/stop.sh"
echo "============================================"
