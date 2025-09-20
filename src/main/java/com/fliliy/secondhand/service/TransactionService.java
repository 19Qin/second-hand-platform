package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.request.*;
import com.fliliy.secondhand.dto.response.*;
import com.fliliy.secondhand.entity.*;
import com.fliliy.secondhand.repository.*;
import com.fliliy.secondhand.util.IdGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;

@Service
@Transactional
public class TransactionService {
    
    private static final Logger logger = LoggerFactory.getLogger(TransactionService.class);
    
    @Autowired
    private TransactionRepository transactionRepository;
    
    @Autowired
    private ChatService chatService;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ProductRepository productRepository;
    
    /**
     * 发起咨询/交易意向
     */
    public InquiryResponse createInquiry(Long userId, InquiryRequest request) {
        logger.info("User {} creating inquiry for product {}", userId, request.getProductId());
        
        // 验证商品存在且可交易
        Product product = productRepository.findById(request.getProductId())
            .orElseThrow(() -> new RuntimeException("商品不存在"));
        
        if (!Product.ProductStatus.ACTIVE.equals(product.getStatus())) {
            throw new RuntimeException("商品不可交易");
        }
        
        // 验证不能与自己交易
        if (userId.equals(request.getSellerId())) {
            throw new RuntimeException("不能与自己交易");
        }
        
        // 验证卖家存在
        User seller = userRepository.findById(request.getSellerId())
            .orElseThrow(() -> new RuntimeException("卖家不存在"));
        
        // 检查是否已有交易记录
        Optional<Transaction> existingTransaction = transactionRepository
            .findByBuyerIdAndProductId(userId, request.getProductId());
        
        if (existingTransaction.isPresent()) {
            Transaction transaction = existingTransaction.get();
            // 如果已取消，可以重新发起
            if (!Transaction.TransactionStatus.CANCELLED.equals(transaction.getStatus())) {
                throw new RuntimeException("已存在交易记录");
            }
        }
        
        // 创建或获取聊天室
        ChatRoom chatRoom = chatService.createOrGetChatRoom(request.getProductId(), userId);
        Long chatRoomId = chatRoom.getId();
        
        // 创建交易记录
        Transaction transaction = new Transaction();
        transaction.setId(IdGenerator.generateProductId());
        transaction.setBuyerId(userId);
        transaction.setSellerId(request.getSellerId());
        transaction.setProductId(request.getProductId());
        transaction.setChatRoomId(chatRoomId);
        transaction.setStatus(Transaction.TransactionStatus.INQUIRY);
        transaction.setInquiryType(Transaction.InquiryType.valueOf(request.getInquiryType()));
        transaction.setTransactionPrice(product.getPrice());
        
        transactionRepository.save(transaction);
        
        // 发送咨询消息 - 使用独立事务避免回滚
        SendMessageRequest messageRequest = new SendMessageRequest();
        messageRequest.setType("TEXT");
        messageRequest.setContent(request.getMessage());
        
        try {
            chatService.sendMessage(chatRoomId, userId, messageRequest);
        } catch (Exception e) {
            logger.warn("Failed to send inquiry message: {}", e.getMessage());
            // 不抛出异常，避免影响主事务
        }
        
        // 构建响应
        InquiryResponse response = new InquiryResponse();
        response.setTransactionId("tx_" + transaction.getId());
        response.setChatRoomId(chatRoomId);
        response.setStatus(transaction.getStatus().name());
        
        return response;
    }
    
    /**
     * 同意线下交易
     */
    public AgreeOfflineResponse agreeOfflineTransaction(Long userId, Long transactionId, AgreeOfflineRequest request) {
        logger.info("User {} agreeing offline transaction {}", userId, transactionId);
        
        // 获取交易记录
        Transaction transaction = transactionRepository.findById(transactionId)
            .orElseThrow(() -> new RuntimeException("交易不存在"));
        
        // 验证权限（只有卖家可以同意）
        if (!userId.equals(transaction.getSellerId())) {
            throw new RuntimeException("无权限操作此交易");
        }
        
        // 验证交易状态
        if (!Transaction.TransactionStatus.INQUIRY.equals(transaction.getStatus())) {
            throw new RuntimeException("交易状态不正确");
        }
        
        // 生成4位交易验证码
        String transactionCode = generateTransactionCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusHours(24);
        
        // 更新交易记录
        transaction.setStatus(Transaction.TransactionStatus.AGREED);
        transaction.setTransactionCode(transactionCode);
        transaction.setCodeExpiresAt(expiresAt);
        transaction.setMeetingTime(request.getMeetingTime());
        transaction.setContactName(request.getContactInfo().getContactName());
        transaction.setContactPhone(request.getContactInfo().getContactPhone());
        transaction.setMeetingLocationName(request.getMeetingLocation().getLocationName());
        transaction.setMeetingDetailAddress(request.getMeetingLocation().getDetailAddress());
        transaction.setMeetingLongitude(request.getMeetingLocation().getLongitude());
        transaction.setMeetingLatitude(request.getMeetingLocation().getLatitude());
        transaction.setMeetingNotes(request.getNotes());
        
        transactionRepository.save(transaction);
        
        // 发送系统消息到聊天室
        try {
            SendMessageRequest systemMessage = new SendMessageRequest();
            systemMessage.setType("SYSTEM");
            systemMessage.setContent("双方已同意线下交易，交易码：" + transactionCode);
            
            chatService.sendMessage(userId, transaction.getChatRoomId(), systemMessage);
        } catch (Exception e) {
            logger.warn("Failed to send system message: {}", e.getMessage());
        }
        
        // 构建响应
        AgreeOfflineResponse response = new AgreeOfflineResponse();
        response.setTransactionCode(transactionCode);
        response.setExpiresAt(expiresAt);
        
        AgreeOfflineResponse.MeetingInfo meetingInfo = new AgreeOfflineResponse.MeetingInfo();
        meetingInfo.setMeetingTime(request.getMeetingTime());
        meetingInfo.setLocationName(request.getMeetingLocation().getLocationName());
        meetingInfo.setContactName(request.getContactInfo().getContactName());
        // 脱敏显示手机号
        meetingInfo.setContactPhone(maskPhone(request.getContactInfo().getContactPhone()));
        
        response.setMeetingInfo(meetingInfo);
        
        return response;
    }
    
    /**
     * 确认交易完成
     */
    public CompleteTransactionResponse completeTransaction(Long userId, Long transactionId, CompleteTransactionRequest request) {
        logger.info("User {} completing transaction {}", userId, transactionId);
        
        // 获取交易记录
        Transaction transaction = transactionRepository.findById(transactionId)
            .orElseThrow(() -> new RuntimeException("交易不存在"));
        
        // 验证权限（只有卖家可以确认完成）
        if (!userId.equals(transaction.getSellerId())) {
            throw new RuntimeException("无权限操作此交易");
        }
        
        // 验证交易状态
        if (!Transaction.TransactionStatus.AGREED.equals(transaction.getStatus())) {
            throw new RuntimeException("交易状态不正确");
        }
        
        // 验证交易码
        if (!request.getTransactionCode().equals(transaction.getTransactionCode())) {
            throw new RuntimeException("交易验证码错误");
        }
        
        // 验证交易码是否过期
        if (LocalDateTime.now().isAfter(transaction.getCodeExpiresAt())) {
            throw new RuntimeException("交易验证码已过期");
        }
        
        // 更新交易记录
        transaction.setStatus(Transaction.TransactionStatus.COMPLETED);
        transaction.setCompletedAt(LocalDateTime.now());
        transaction.setFeedback(request.getFeedback());
        transaction.setRating(request.getRating());
        
        transactionRepository.save(transaction);
        
        // 更新商品状态为已售出
        Product product = productRepository.findById(transaction.getProductId())
            .orElseThrow(() -> new RuntimeException("商品不存在"));
        product.setStatus(Product.ProductStatus.SOLD);
        productRepository.save(product);
        
        // 发送交易完成消息
        try {
            SendMessageRequest systemMessage = new SendMessageRequest();
            systemMessage.setType("SYSTEM");
            systemMessage.setContent("交易已完成！感谢使用Fliliy二手交易平台");
            
            chatService.sendMessage(userId, transaction.getChatRoomId(), systemMessage);
        } catch (Exception e) {
            logger.warn("Failed to send completion message: {}", e.getMessage());
        }
        
        // 构建响应
        CompleteTransactionResponse response = new CompleteTransactionResponse();
        response.setTransactionId("tx_" + transaction.getId());
        response.setStatus(transaction.getStatus().name());
        response.setCompletedAt(transaction.getCompletedAt());
        response.setProductStatus("SOLD");
        
        return response;
    }
    
    /**
     * 取消交易
     */
    public void cancelTransaction(Long userId, Long transactionId, CancelTransactionRequest request) {
        logger.info("User {} cancelling transaction {}", userId, transactionId);
        
        // 获取交易记录
        Transaction transaction = transactionRepository.findById(transactionId)
            .orElseThrow(() -> new RuntimeException("交易不存在"));
        
        // 验证权限
        if (!userId.equals(transaction.getBuyerId()) && !userId.equals(transaction.getSellerId())) {
            throw new RuntimeException("无权限操作此交易");
        }
        
        // 验证交易状态
        if (Transaction.TransactionStatus.COMPLETED.equals(transaction.getStatus()) ||
            Transaction.TransactionStatus.CANCELLED.equals(transaction.getStatus())) {
            throw new RuntimeException("交易已完成或已取消");
        }
        
        // 更新交易记录
        transaction.setStatus(Transaction.TransactionStatus.CANCELLED);
        transaction.setCancelReason(request.getReason());
        transaction.setCancelType(Transaction.CancelType.valueOf(request.getCancelType()));
        transaction.setCancelledAt(LocalDateTime.now());
        
        transactionRepository.save(transaction);
        
        // 发送取消消息
        try {
            SendMessageRequest systemMessage = new SendMessageRequest();
            systemMessage.setType("SYSTEM");
            systemMessage.setContent("交易已取消：" + request.getReason());
            
            chatService.sendMessage(userId, transaction.getChatRoomId(), systemMessage);
        } catch (Exception e) {
            logger.warn("Failed to send cancellation message: {}", e.getMessage());
        }
    }
    
    /**
     * 获取交易记录
     */
    public Page<TransactionResponse> getTransactions(Long userId, String type, String status, int page, int size) {
        logger.info("Getting transactions for user {}, type: {}, status: {}", userId, type, status);
        
        Pageable pageable = PageRequest.of(page - 1, size);
        Page<Transaction> transactions;
        
        // 根据类型和状态查询
        if ("all".equals(status)) {
            if ("buy".equals(type)) {
                transactions = transactionRepository.findByBuyerIdOrderByCreatedAtDesc(userId, pageable);
            } else if ("sell".equals(type)) {
                transactions = transactionRepository.findBySellerIdOrderByCreatedAtDesc(userId, pageable);
            } else {
                transactions = transactionRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
            }
        } else {
            Transaction.TransactionStatus transactionStatus = Transaction.TransactionStatus.valueOf(status.toUpperCase());
            transactions = transactionRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, transactionStatus, pageable);
        }
        
        // 转换为响应对象
        return transactions.map(this::convertToTransactionResponse);
    }
    
    /**
     * 转换为TransactionResponse
     */
    private TransactionResponse convertToTransactionResponse(Transaction transaction) {
        TransactionResponse response = new TransactionResponse();
        response.setId("tx_" + transaction.getId());
        response.setStatus(transaction.getStatus().name());
        response.setStatusText(getStatusText(transaction.getStatus()));
        response.setTransactionTime(transaction.getCompletedAt() != null ? transaction.getCompletedAt() : transaction.getCreatedAt());
        response.setCanRate(transaction.getStatus() == Transaction.TransactionStatus.COMPLETED && transaction.getRating() == null);
        response.setRating(transaction.getRating());
        
        // 设置交易类型（买入/卖出）
        // 注意：这里需要根据当前用户ID来判断
        
        // 获取商品信息
        try {
            Optional<Product> productOpt = productRepository.findById(transaction.getProductId());
            if (productOpt.isPresent()) {
                Product product = productOpt.get();
                TransactionResponse.ProductInfo productInfo = new TransactionResponse.ProductInfo();
                productInfo.setId(String.valueOf(product.getId()));
                productInfo.setTitle(product.getTitle());
                productInfo.setPrice(product.getPrice());
                productInfo.setMainImage(getMainImageUrl(product.getId()));
                response.setProduct(productInfo);
            }
        } catch (Exception e) {
            logger.warn("Failed to load product info: {}", e.getMessage());
        }
        
        // 设置见面信息
        if (transaction.getMeetingTime() != null) {
            TransactionResponse.MeetingInfo meetingInfo = new TransactionResponse.MeetingInfo();
            meetingInfo.setMeetingTime(transaction.getMeetingTime());
            meetingInfo.setLocationName(transaction.getMeetingLocationName());
            response.setMeetingInfo(meetingInfo);
        }
        
        return response;
    }
    
    /**
     * 获取状态显示文本
     */
    private String getStatusText(Transaction.TransactionStatus status) {
        Map<Transaction.TransactionStatus, String> statusMap = new HashMap<>();
        statusMap.put(Transaction.TransactionStatus.INQUIRY, "咨询中");
        statusMap.put(Transaction.TransactionStatus.AGREED, "已同意");
        statusMap.put(Transaction.TransactionStatus.COMPLETED, "交易完成");
        statusMap.put(Transaction.TransactionStatus.CANCELLED, "已取消");
        
        return statusMap.get(status);
    }
    
    /**
     * 生成4位交易验证码
     */
    private String generateTransactionCode() {
        Random random = new Random();
        return String.format("%04d", random.nextInt(10000));
    }
    
    /**
     * 手机号脱敏
     */
    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
    
    /**
     * 获取商品主图URL（简化实现）
     */
    private String getMainImageUrl(Long productId) {
        // 这里应该查询ProductImage表获取主图
        // 简化实现，返回占位符
        return "http://localhost:8080/api/v1/files/products/default.jpg";
    }
}