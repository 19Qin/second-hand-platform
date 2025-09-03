package com.fliliy.secondhand.entity;

import lombok.Data;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "verification_codes")
@Data
public class VerificationCode {
    
    @Id
    @Column(length = 50)
    private String id;
    
    @Column(length = 20)
    private String mobile;
    
    @Column(length = 100)
    private String email;
    
    @Column(nullable = false, length = 4)
    private String code;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private CodeType type;
    
    @Column(columnDefinition = "INT DEFAULT 0")
    private Integer attempts = 0;
    
    @Column(name = "max_attempts", columnDefinition = "INT DEFAULT 5")
    private Integer maxAttempts = 5;
    
    @Column(columnDefinition = "BOOLEAN DEFAULT FALSE")
    private Boolean used = false;
    
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    public enum CodeType {
        REGISTER, LOGIN, RESET, BIND
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}