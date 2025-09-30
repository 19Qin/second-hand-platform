package com.fliliy.secondhand.task;

import com.fliliy.secondhand.entity.Transaction;
import com.fliliy.secondhand.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

@Component
@RequiredArgsConstructor
@Slf4j
public class TransactionCodeRefreshTask {
    
    private final TransactionRepository transactionRepository;
    
    /**
     * 每天凌晨1点执行，刷新即将过期的交易码
     */
    @Scheduled(cron = "0 0 1 * * ?")
    public void refreshExpiredTransactionCodes() {
        log.info("开始执行交易码刷新任务");
        
        try {
            // 查找所有状态为AGREED且交易码将在24小时内过期的交易
            LocalDateTime expireTime = LocalDateTime.now().plusHours(24);
            List<Transaction> transactions = transactionRepository
                    .findByStatusAndCodeExpiresAtBefore(
                            Transaction.TransactionStatus.AGREED, 
                            expireTime
                    );
            
            log.info("找到{}个需要刷新交易码的交易", transactions.size());
            
            int successCount = 0;
            for (Transaction transaction : transactions) {
                try {
                    // 生成新的交易码
                    String newCode = generateTransactionCode();
                    transaction.setTransactionCode(newCode);
                    transaction.setCodeExpiresAt(LocalDateTime.now().plusHours(24));
                    
                    // 增加刷新计数
                    Integer currentCount = transaction.getCodeRefreshCount();
                    transaction.setCodeRefreshCount(currentCount != null ? currentCount + 1 : 1);
                    
                    transactionRepository.save(transaction);
                    successCount++;
                    
                    log.debug("交易ID: {} 的交易码已刷新为: {}", transaction.getId(), newCode);
                    
                } catch (Exception e) {
                    log.error("刷新交易ID: {} 的交易码失败: {}", transaction.getId(), e.getMessage(), e);
                }
            }
            
            log.info("交易码刷新任务完成，成功刷新{}个交易", successCount);
            
        } catch (Exception e) {
            log.error("执行交易码刷新任务失败: {}", e.getMessage(), e);
        }
    }
    
    /**
     * 生成4位数字交易码
     */
    private String generateTransactionCode() {
        Random random = new Random();
        return String.format("%04d", random.nextInt(10000));
    }
}