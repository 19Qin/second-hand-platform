package com.fliliy.secondhand.config;

import com.fliliy.secondhand.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;
import org.springframework.web.socket.server.HandshakeInterceptor;

import javax.servlet.http.HttpServletRequest;
import java.util.Map;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
@Slf4j
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtUtil jwtUtil;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // 启用简单消息代理，用于向客户端发送消息
        config.enableSimpleBroker("/topic", "/queue", "/user");
        
        // 设置应用程序消息前缀，客户端发送消息时使用
        config.setApplicationDestinationPrefixes("/app");
        
        // 设置用户消息前缀，用于点对点消息
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // 注册WebSocket端点，客户端通过此端点连接
        registry.addEndpoint("/ws")
                .addInterceptors(new JwtHandshakeInterceptor())
                .setAllowedOriginPatterns("*") // 允许跨域
                .withSockJS(); // 启用SockJS支持

        // 注册原生WebSocket端点（不使用SockJS）
        registry.addEndpoint("/ws")
                .addInterceptors(new JwtHandshakeInterceptor())
                .setAllowedOriginPatterns("*");
    }

    /**
     * JWT握手拦截器，用于在WebSocket连接时验证JWT令牌
     */
    private class JwtHandshakeInterceptor implements HandshakeInterceptor {

        @Override
        public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                     WebSocketHandler wsHandler, Map<String, Object> attributes) throws Exception {
            
            log.info("WebSocket handshake attempt from: {}", request.getRemoteAddress());
            
            // 从查询参数中获取token
            String token = getTokenFromRequest(request);
            
            if (token == null || token.isEmpty()) {
                log.warn("WebSocket handshake failed: No token provided");
                return false;
            }

            // 验证JWT令牌
            if (!jwtUtil.validateToken(token)) {
                log.warn("WebSocket handshake failed: Invalid token");
                return false;
            }

            // 从令牌中提取用户信息并存储在WebSocket会话属性中
            try {
                String userId = jwtUtil.getUserIdFromToken(token);
                String mobile = jwtUtil.getMobileFromToken(token);
                
                attributes.put("userId", userId);
                attributes.put("mobile", mobile);
                attributes.put("token", token);
                
                log.info("WebSocket handshake successful for user: {} ({})", userId, mobile);
                return true;
                
            } catch (Exception e) {
                log.error("WebSocket handshake failed: Error extracting user info from token", e);
                return false;
            }
        }

        @Override
        public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                 WebSocketHandler wsHandler, Exception exception) {
            if (exception != null) {
                log.error("WebSocket handshake completed with error", exception);
            } else {
                log.info("WebSocket handshake completed successfully");
            }
        }

        /**
         * 从请求中提取JWT令牌
         * 支持查询参数和Authorization头两种方式
         */
        private String getTokenFromRequest(ServerHttpRequest request) {
            // 1. 尝试从查询参数中获取token
            String query = request.getURI().getQuery();
            if (query != null) {
                String[] params = query.split("&");
                for (String param : params) {
                    if (param.startsWith("token=")) {
                        return param.substring(6); // 去掉"token="前缀
                    }
                }
            }

            // 2. 尝试从Authorization头中获取token
            if (request instanceof ServletServerHttpRequest) {
                HttpServletRequest servletRequest = ((ServletServerHttpRequest) request).getServletRequest();
                String authHeader = servletRequest.getHeader("Authorization");
                if (authHeader != null && authHeader.startsWith("Bearer ")) {
                    return authHeader.substring(7); // 去掉"Bearer "前缀
                }
            }

            return null;
        }
    }
}