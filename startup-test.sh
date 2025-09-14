#!/bin/bash

echo "🚀 开始测试 Spring Boot 应用启动"
echo "================================"

cd /Users/yit/Desktop/second-hand-platform2

echo "1. 检查Maven配置..."
mvn -version

echo -e "\n2. 清理项目..."
mvn clean

echo -e "\n3. 编译项目..."
mvn compile

if [ $? -eq 0 ]; then
    echo "✅ 编译成功！"
    
    echo -e "\n4. 运行测试（超时30秒）..."
    timeout 30s mvn spring-boot:run &
    PID=$!
    
    sleep 25
    
    if ps -p $PID > /dev/null; then
        echo "✅ 应用启动成功！正在停止..."
        kill $PID
        wait $PID 2>/dev/null
        echo "🎉 修复完成！应用可以正常启动"
    else
        echo "❌ 应用启动失败或已异常退出"
    fi
else
    echo "❌ 编译失败，请检查代码"
fi

echo -e "\n================================"
echo "测试完成"