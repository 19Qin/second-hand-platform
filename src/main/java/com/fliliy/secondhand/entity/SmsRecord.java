package com.fliliy.secondhand.entity;

import lombok.Data;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "sms_records")
@Data
public class SmsRecord {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 20)
    private String mobile;
    
    @Column(nullable = false, length = 4)
    private String code;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private SmsType type;
    
    @Column(name = "template_code", length = 50)
    private String templateCode;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "send_status", length = 20)
    private SendStatus sendStatus = SendStatus.PENDING;
    
    @Column(length = 50)
    private String provider = "mock";
    
    @Column(name = "provider_msg_id", length = 100)
    private String providerMsgId;
    
    @Column(name = "error_code", length = 50)
    private String errorCode;
    
    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;
    
    @Column(name = "cost_amount", precision = 10, scale = 4)
    private BigDecimal costAmount = BigDecimal.ZERO;
    
    @Column(name = "ip_address", length = 45)
    private String ipAddress;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "sent_at")
    private LocalDateTime sentAt;
    
    public enum SmsType {
        REGISTER, LOGIN, RESET, BIND
    }
    
    public enum SendStatus {
        PENDING, SUCCESS, FAILED
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}