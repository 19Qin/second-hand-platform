package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.UserAddress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserAddressRepository extends JpaRepository<UserAddress, Long> {
    
    List<UserAddress> findByUserIdOrderByIsDefaultDescCreatedAtDesc(Long userId);
    
    @Query("SELECT ua FROM UserAddress ua WHERE ua.userId = :userId AND ua.isDefault = true")
    UserAddress findDefaultAddressByUserId(@Param("userId") Long userId);
    
    @Modifying
    @Query("UPDATE UserAddress ua SET ua.isDefault = false WHERE ua.userId = :userId")
    void clearDefaultAddressByUserId(@Param("userId") Long userId);
    
    @Modifying
    @Query("UPDATE UserAddress ua SET ua.usageCount = ua.usageCount + 1, ua.lastUsedAt = CURRENT_TIMESTAMP WHERE ua.id = :addressId")
    void incrementUsageCount(@Param("addressId") Long addressId);
}