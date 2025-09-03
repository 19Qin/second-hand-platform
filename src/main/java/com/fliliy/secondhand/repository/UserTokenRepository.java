package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.UserToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import javax.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserTokenRepository extends JpaRepository<UserToken, Long> {
    
    Optional<UserToken> findByRefreshTokenAndRevokedFalseAndExpiresAtAfter(String refreshToken, LocalDateTime now);
    
    List<UserToken> findByUserIdAndRevokedFalse(Long userId);
    
    @Modifying
    @Transactional
    @Query("UPDATE UserToken t SET t.revoked = true WHERE t.userId = :userId")
    void revokeAllByUserId(@Param("userId") Long userId);
    
    @Modifying
    @Transactional
    @Query("UPDATE UserToken t SET t.revoked = true WHERE t.refreshToken = :refreshToken")
    void revokeByRefreshToken(@Param("refreshToken") String refreshToken);
    
    @Modifying
    @Transactional
    @Query("DELETE FROM UserToken t WHERE t.expiresAt < :now OR t.revoked = true")
    void deleteExpiredAndRevoked(@Param("now") LocalDateTime now);
    
    @Query("SELECT COUNT(t) FROM UserToken t WHERE t.userId = :userId AND t.revoked = false AND t.expiresAt > :now")
    long countActiveTokensByUserId(@Param("userId") Long userId, @Param("now") LocalDateTime now);
}