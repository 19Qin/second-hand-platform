package com.fliliy.secondhand.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
@Slf4j
public class JwtUtil {
    
    @Value("${jwt.secret}")
    private String secret;
    
    @Value("${jwt.access-token-expire-hours}")
    private Integer accessTokenExpireHours;
    
    @Value("${jwt.refresh-token-expire-days}")
    private Integer refreshTokenExpireDays;
    
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }
    
    /**
     * 生成访问令牌
     */
    public String generateAccessToken(String userId, String mobile) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + accessTokenExpireHours * 60 * 60 * 1000L);
        
        return Jwts.builder()
                .setSubject(userId)
                .claim("mobile", mobile)
                .claim("type", "access")
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }
    
    /**
     * 生成刷新令牌
     */
    public String generateRefreshToken(String userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshTokenExpireDays * 24 * 60 * 60 * 1000L);
        
        return Jwts.builder()
                .setSubject(userId)
                .claim("type", "refresh")
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }
    
    /**
     * 从令牌中获取用户ID
     */
    public String getUserIdFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims.getSubject();
    }
    
    /**
     * 从令牌中获取手机号
     */
    public String getMobileFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return (String) claims.get("mobile");
    }
    
    /**
     * 验证令牌
     */
    public boolean validateToken(String token) {
        try {
            Claims claims = getClaimsFromToken(token);
            return !claims.getExpiration().before(new Date());
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("JWT validation failed: {}", e.getMessage());
            return false;
        }
    }
    
    /**
     * 获取令牌过期时间
     */
    public Date getExpirationDateFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims.getExpiration();
    }
    
    /**
     * 获取访问令牌过期时间（秒）
     */
    public long getAccessTokenExpireSeconds() {
        return accessTokenExpireHours * 60 * 60L;
    }
    
    /**
     * 获取刷新令牌过期时间（秒）
     */
    public long getRefreshTokenExpireSeconds() {
        return refreshTokenExpireDays * 24 * 60 * 60L;
    }
    
    private Claims getClaimsFromToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
}