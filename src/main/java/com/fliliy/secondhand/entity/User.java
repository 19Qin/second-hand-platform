package com.fliliy.secondhand.entity;

import lombok.Data;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.Where;

import javax.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data
@SQLDelete(sql = "UPDATE users SET deleted_at = NOW() WHERE id = ?")
@Where(clause = "deleted_at IS NULL")
public class User {
    
    @Id
    private Long id;
    
    @Column(nullable = false, length = 50)
    private String username;
    
    @Column(unique = true, length = 20)
    private String mobile;
    
    @Column(length = 100)
    private String email;
    
    @Column(name = "password_hash", length = 255)
    private String passwordHash;
    
    @Column(length = 50)
    private String salt;
    
    @Column(length = 500)
    private String avatar = "https://cdn.fliliy.com/avatar/default.png";
    
    @Column(columnDefinition = "TINYINT DEFAULT 0")
    private Integer gender = 0;
    
    private LocalDate birthday;
    
    @Column(length = 200)
    private String location;
    
    @Column(columnDefinition = "TEXT")
    private String bio;
    
    @Column(columnDefinition = "BOOLEAN DEFAULT FALSE")
    private Boolean verified = false;
    
    @Column(columnDefinition = "TINYINT DEFAULT 1")
    private Integer status = 1;
    
    @Column(name = "login_attempts", columnDefinition = "INT DEFAULT 0")
    private Integer loginAttempts = 0;
    
    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;
    
    @Column(name = "last_login_ip", length = 45)
    private String lastLoginIp;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}