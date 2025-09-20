package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    /**
     * 根据买家ID和商品ID查找交易记录
     */
    Optional<Transaction> findByBuyerIdAndProductId(Long buyerId, Long productId);
    
    /**
     * 根据买家或卖家ID查找交易记录（分页）
     */
    @Query("SELECT t FROM Transaction t WHERE t.buyerId = :userId OR t.sellerId = :userId ORDER BY t.createdAt DESC")
    Page<Transaction> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);
    
    /**
     * 根据买家ID查找交易记录（分页）
     */
    Page<Transaction> findByBuyerIdOrderByCreatedAtDesc(Long buyerId, Pageable pageable);
    
    /**
     * 根据卖家ID查找交易记录（分页）
     */
    Page<Transaction> findBySellerIdOrderByCreatedAtDesc(Long sellerId, Pageable pageable);
    
    /**
     * 根据状态和用户ID查找交易记录
     */
    @Query("SELECT t FROM Transaction t WHERE (t.buyerId = :userId OR t.sellerId = :userId) AND t.status = :status ORDER BY t.createdAt DESC")
    Page<Transaction> findByUserIdAndStatusOrderByCreatedAtDesc(@Param("userId") Long userId, 
                                                                @Param("status") Transaction.TransactionStatus status, 
                                                                Pageable pageable);
    
    /**
     * 根据商品ID查找交易记录
     */
    List<Transaction> findByProductIdOrderByCreatedAtDesc(Long productId);
    
    /**
     * 根据聊天室ID查找交易记录
     */
    Optional<Transaction> findByChatRoomId(Long chatRoomId);
    
    /**
     * 查找过期的交易验证码
     */
    @Query("SELECT t FROM Transaction t WHERE t.status = :status AND t.codeExpiresAt < :now")
    List<Transaction> findExpiredTransactionCodes(@Param("status") Transaction.TransactionStatus status, 
                                                  @Param("now") LocalDateTime now);
    
    /**
     * 统计用户作为买家的交易数量
     */
    long countByBuyerIdAndStatus(Long buyerId, Transaction.TransactionStatus status);
    
    /**
     * 统计用户作为卖家的交易数量
     */
    long countBySellerIdAndStatus(Long sellerId, Transaction.TransactionStatus status);
    
    /**
     * 统计商品的交易数量
     */
    long countByProductIdAndStatus(Long productId, Transaction.TransactionStatus status);
    
    /**
     * 查找用户最近的交易记录
     */
    @Query("SELECT t FROM Transaction t WHERE (t.buyerId = :userId OR t.sellerId = :userId) ORDER BY t.createdAt DESC")
    List<Transaction> findRecentTransactionsByUserId(@Param("userId") Long userId, Pageable pageable);
    
    /**
     * 查找待评价的交易（已完成但未评价）
     */
    @Query("SELECT t FROM Transaction t WHERE (t.buyerId = :userId OR t.sellerId = :userId) " +
           "AND t.status = :status AND t.rating IS NULL ORDER BY t.completedAt DESC")
    List<Transaction> findPendingRatingTransactions(@Param("userId") Long userId, 
                                                    @Param("status") Transaction.TransactionStatus status);
    
    /**
     * 根据交易码查找交易
     */
    Optional<Transaction> findByTransactionCode(String transactionCode);
}