#!/bin/bash

# Elasticsearch镜像下载进度检查脚本

echo "================================================"
echo "  Elasticsearch 镜像下载进度检查"
echo "================================================"
echo ""
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 检查镜像是否已下载
if docker images | grep -q "elasticsearch.*7.17.10"; then
    echo "✅ 镜像已下载完成！"
    echo ""
    docker images | grep elasticsearch
    echo ""
    echo "下一步操作："
    echo "1. 启动容器: cd /Users/yit/Desktop/second-hand-platform2 && docker-compose -f docker-compose-es.yml up -d"
    echo "2. 查看日志: docker logs fliliy-es"
    echo "3. 验证服务: curl http://localhost:9200"
else
    echo "⏳ 镜像还在下载中..."
    echo ""

    # 检查是否有正在运行的docker pull进程
    if ps aux | grep -q "[d]ocker.*pull.*elasticsearch"; then
        echo "🔄 检测到下载进程正在运行"
        ps aux | grep "[d]ocker.*pull" | head -1
    else
        echo "❌ 未检测到下载进程"
        echo ""
        echo "重新启动下载："
        echo "docker pull docker.elastic.co/elasticsearch/elasticsearch:7.17.10"
    fi

    echo ""
    echo "当前Docker镜像列表："
    docker images | head -5
fi

echo ""
echo "================================================"
