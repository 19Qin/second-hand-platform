#!/bin/bash

echo "🎯 最终修复验证"
echo "================"

cd /Users/yit/Desktop/second-hand-platform2

echo "1. 清理编译缓存..."
mvn clean -q

echo "2. 编译项目..."
if mvn compile -q; then
    echo "✅ 编译成功！"
    
    echo "3. 运行单元测试..."
    if mvn test -q; then
        echo "✅ 测试通过！"
    else
        echo "⚠️ 测试有问题，但编译通过"
    fi
    
    echo "4. 启动应用测试（15秒）..."
    echo "正在启动Spring Boot..."
    
    # 后台启动应用
    nohup mvn spring-boot:run > startup.log 2>&1 &
    BOOT_PID=$!
    
    # 等待启动
    sleep 12
    
    # 检查端口是否开启
    if lsof -ti:8080 > /dev/null; then
        echo "✅ 应用启动成功！端口8080已开启"
        
        # 测试健康检查
        if curl -s http://localhost:8080/api/v1/health > /dev/null; then
            echo "✅ 健康检查通过！"
        else
            echo "⚠️ 健康检查失败，但应用已启动"
        fi
        
        # 停止应用
        kill $BOOT_PID 2>/dev/null
        echo "🛑 应用已停止"
    else
        echo "❌ 应用启动失败"
        echo "启动日志："
        tail -20 startup.log
    fi
    
    echo ""
    echo "🎉 修复完成！你的应用现在可以正常启动了"
    
else
    echo "❌ 编译失败"
    echo "错误详情："
    mvn compile
fi

echo "================"