package com.fliliy.secondhand.health;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

/**
 * 数据库健康检查指示器
 * 检查数据库连接状态和响应时间
 */
@Component
public class DatabaseHealthIndicator implements HealthIndicator {

    private final DataSource dataSource;

    public DatabaseHealthIndicator(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Health health() {
        try {
            long startTime = System.currentTimeMillis();

            // 执行简单查询测试数据库连接
            try (Connection connection = dataSource.getConnection();
                 Statement statement = connection.createStatement();
                 ResultSet resultSet = statement.executeQuery("SELECT 1")) {

                if (resultSet.next()) {
                    long responseTime = System.currentTimeMillis() - startTime;

                    return Health.up()
                            .withDetail("database", "MySQL")
                            .withDetail("responseTime", responseTime + "ms")
                            .withDetail("status", "Connected")
                            .build();
                }
            }

            return Health.down()
                    .withDetail("database", "MySQL")
                    .withDetail("error", "Query failed")
                    .build();

        } catch (Exception e) {
            return Health.down()
                    .withDetail("database", "MySQL")
                    .withDetail("error", e.getMessage())
                    .build();
        }
    }
}
