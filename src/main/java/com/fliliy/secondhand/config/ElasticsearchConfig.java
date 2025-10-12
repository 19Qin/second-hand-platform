package com.fliliy.secondhand.config;

import org.apache.http.HttpHost;
import org.elasticsearch.client.RestClient;
import org.elasticsearch.client.RestHighLevelClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Elasticsearch 配置
 */
@Configuration
public class ElasticsearchConfig {

    @Value("${spring.elasticsearch.uris:http://localhost:9200}")
    private String elasticsearchUri;

    @Bean
    public RestHighLevelClient restHighLevelClient() {
        // 解析 URI
        String host = "localhost";
        int port = 9200;

        try {
            String uri = elasticsearchUri.replace("http://", "").replace("https://", "");
            String[] parts = uri.split(":");
            if (parts.length >= 1) {
                host = parts[0];
            }
            if (parts.length >= 2) {
                port = Integer.parseInt(parts[1]);
            }
        } catch (Exception e) {
            // 使用默认值
        }

        return new RestHighLevelClient(
            RestClient.builder(new HttpHost(host, port, "http"))
                .setRequestConfigCallback(requestConfigBuilder ->
                    requestConfigBuilder
                        .setConnectTimeout(5000)
                        .setSocketTimeout(60000)
                        .setConnectionRequestTimeout(5000))
        );
    }
}
