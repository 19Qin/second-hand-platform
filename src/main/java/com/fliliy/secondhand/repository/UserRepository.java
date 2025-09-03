package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import javax.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByMobile(String mobile);
    
    Optional<User> findByEmail(String email);
    
    boolean existsByMobile(String mobile);
    
    boolean existsByEmail(String email);
    
    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.loginAttempts = :attempts WHERE u.id = :userId")
    void updateLoginAttempts(@Param("userId") Long userId, @Param("attempts") Integer attempts);
    
    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.lastLoginAt = :loginTime, u.lastLoginIp = :loginIp, u.loginAttempts = 0 WHERE u.id = :userId")
    void updateLastLogin(@Param("userId") Long userId, @Param("loginTime") LocalDateTime loginTime, @Param("loginIp") String loginIp);
}