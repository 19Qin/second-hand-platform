package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.VerificationCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import javax.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface VerificationCodeRepository extends JpaRepository<VerificationCode, String> {
    
    Optional<VerificationCode> findByMobileAndTypeAndUsedFalseAndExpiresAtAfter(
            String mobile, VerificationCode.CodeType type, LocalDateTime now);
    
    Optional<VerificationCode> findByEmailAndTypeAndUsedFalseAndExpiresAtAfter(
            String email, VerificationCode.CodeType type, LocalDateTime now);
    
    @Query("SELECT COUNT(v) FROM VerificationCode v WHERE v.mobile = :mobile AND v.type = :type AND v.createdAt > :todayStart")
    long countByMobileAndTypeAndCreatedAtAfter(
            @Param("mobile") String mobile,
            @Param("type") VerificationCode.CodeType type,
            @Param("todayStart") LocalDateTime todayStart);
    
    @Query("SELECT v FROM VerificationCode v WHERE v.mobile = :mobile AND v.type = :type AND v.createdAt > :timeLimit ORDER BY v.createdAt DESC")
    Optional<VerificationCode> findLatestByMobileAndTypeAfter(
            @Param("mobile") String mobile,
            @Param("type") VerificationCode.CodeType type,
            @Param("timeLimit") LocalDateTime timeLimit);
    
    @Modifying
    @Transactional
    @Query("UPDATE VerificationCode v SET v.used = true WHERE v.mobile = :mobile AND v.type = :type AND v.used = false")
    void markUsedByMobileAndType(@Param("mobile") String mobile, @Param("type") VerificationCode.CodeType type);
    
    @Modifying
    @Transactional
    @Query("UPDATE VerificationCode v SET v.attempts = v.attempts + 1 WHERE v.id = :id")
    void incrementAttempts(@Param("id") String id);
    
    @Modifying
    @Transactional
    @Query("DELETE FROM VerificationCode v WHERE v.expiresAt < :now OR v.used = true")
    void deleteExpiredAndUsed(@Param("now") LocalDateTime now);
}