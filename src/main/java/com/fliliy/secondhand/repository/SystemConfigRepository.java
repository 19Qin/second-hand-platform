package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.SystemConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SystemConfigRepository extends JpaRepository<SystemConfig, Integer> {
    
    Optional<SystemConfig> findByConfigKey(String configKey);
    
    @Query("SELECT sc FROM SystemConfig sc WHERE sc.isPublic = true")
    List<SystemConfig> findPublicConfigs();
    
    @Query("SELECT sc.configValue FROM SystemConfig sc WHERE sc.configKey = :configKey")
    Optional<String> findValueByKey(@Param("configKey") String configKey);
}