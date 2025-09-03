package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.SmsRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SmsRecordRepository extends JpaRepository<SmsRecord, Long> {
    
    long countByMobileAndTypeAndCreatedAtAfter(
            String mobile, 
            SmsRecord.SmsType type, 
            java.time.LocalDateTime since);
}