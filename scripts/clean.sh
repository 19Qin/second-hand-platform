#!/bin/bash

# ============================================
# Fliliy二手平台 - Docker清理脚本
# ============================================

set -e

echo "============================================"
echo "🧹 清理Fliliy二手平台Docker资源"
echo "============================================"
echo ""
echo "⚠️  警告: 此操作将删除所有容器、镜像和数据卷！"
echo ""
echo -n "确认清理？(yes/no): "
read confirm

if [ "$confirm" != "yes" ]; then
    echo "已取消"
    exit 0
fi

# 进入项目目录
cd "$(dirname "$0")/.."

# 停止并删除容器
echo ""
echo "🛑 停止并删除容器..."
docker-compose down -v

# 删除镜像
echo ""
echo "🗑️  删除应用镜像..."
docker rmi fliliy/second-hand-platform:3.0 2>/dev/null || echo "镜像不存在，跳过"

# 清理悬空镜像
echo ""
echo "🧹 清理悬空镜像..."
docker image prune -f

# 清理未使用的卷
echo ""
echo "🧹 清理未使用的数据卷..."
docker volume prune -f

# 清理本地日志和上传文件
echo ""
echo "🧹 清理本地日志和上传文件..."
rm -rf logs/* uploads/* 2>/dev/null || true

echo ""
echo "============================================"
echo "✅ 清理完成！"
echo "============================================"
echo ""
echo "💡 重新启动请运行: ./scripts/start.sh"
echo ""
