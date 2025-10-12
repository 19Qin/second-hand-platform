# ============================================
# Fliliy二手平台 - 多阶段Docker镜像构建
# ============================================

# -------------------- 阶段1: 构建阶段 --------------------
FROM maven:3.6-jdk-8 AS builder

LABEL maintainer="Fliliy Team"
LABEL stage="builder"

WORKDIR /app

# 复制pom.xml并下载依赖（利用Docker缓存层）
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源代码
COPY src ./src

# 编译打包（跳过测试以加快构建速度）
RUN mvn clean package -DskipTests -B

# -------------------- 阶段2: 运行阶段 --------------------
FROM openjdk:8-jre-alpine

LABEL maintainer="Fliliy Team"
LABEL description="Fliliy Second-hand Platform Backend Service"
LABEL version="3.0"

WORKDIR /app

# 安装必要的工具和字体（解决中文乱码）
RUN apk add --no-cache tzdata fontconfig ttf-dejavu \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

# 从构建阶段复制jar包
COPY --from=builder /app/target/*.jar app.jar

# 创建日志和上传文件目录
RUN mkdir -p /app/logs /app/uploads

# 暴露端口
EXPOSE 8080

# JVM参数优化
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/app/logs/gc.log"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
