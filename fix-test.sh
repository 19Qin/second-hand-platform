#!/bin/bash

echo "🔧 修复HQL LIMIT语法错误测试"
echo "================================"

cd /Users/yit/Desktop/second-hand-platform2

echo "1. 清理编译缓存..."
mvn clean -q

echo "2. 编译项目..."
if mvn compile -q; then
    echo "✅ 编译成功！"
    
    echo "3. 启动测试（10秒）..."
    echo "正在启动Spring Boot应用..."
    
    # 后台启动
    nohup mvn spring-boot:run > app.log 2>&1 &
    APP_PID=$!
    
    # 等待启动
    sleep 8
    
    # 检查是否启动成功
    if ps -p $APP_PID > /dev/null; then
        echo "✅ 应用正在运行..."
        
        # 检查端口
        if lsof -ti:8080 > /dev/null; then
            echo "✅ 端口8080已开启"
            
            # 测试健康检查
            if curl -s -f http://localhost:8080/api/v1/health > /dev/null; then
                echo "✅ 健康检查成功！"
                echo "🎉 所有修复完成，应用正常运行！"
            else
                echo "⚠️ 健康检查失败，但应用已启动"
            fi
        else
            echo "⚠️ 端口未开启，可能仍在启动中"
        fi
        
        # 停止应用
        echo "🛑 停止应用..."
        kill $APP_PID
        sleep 2
        
    else
        echo "❌ 应用启动失败，查看日志："
        tail -20 app.log
    fi
    
else
    echo "❌ 编译失败，详细错误："
    mvn compile
fi

echo "================================"
echo "测试完成"