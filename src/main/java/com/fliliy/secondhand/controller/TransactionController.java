package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.*;
import com.fliliy.secondhand.dto.response.*;
import com.fliliy.secondhand.service.TransactionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/transactions")
@RequiredArgsConstructor
@Slf4j
public class TransactionController {
    
    private final TransactionService transactionService;
    
    /**
     * 发起咨询/交易意向
     */
    @PostMapping("/inquiry")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<InquiryResponse> createInquiry(
            @Valid @RequestBody InquiryRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            InquiryResponse response = transactionService.createInquiry(userId, request);
            return ApiResponse.success("咨询发起成功", response);
        } catch (Exception e) {
            log.error("Create inquiry failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 同意线下交易
     */
    @PostMapping("/{transactionId}/agree-offline")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<AgreeOfflineResponse> agreeOfflineTransaction(
            @PathVariable String transactionId,
            @Valid @RequestBody AgreeOfflineRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            // 从字符串ID中提取数字ID
            Long numericTransactionId = extractTransactionId(transactionId);
            AgreeOfflineResponse response = transactionService.agreeOfflineTransaction(userId, numericTransactionId, request);
            return ApiResponse.success("线下交易确认成功", response);
        } catch (Exception e) {
            log.error("Agree offline transaction failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 确认交易完成
     */
    @PostMapping("/{transactionId}/complete")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<CompleteTransactionResponse> completeTransaction(
            @PathVariable String transactionId,
            @Valid @RequestBody CompleteTransactionRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            // 从字符串ID中提取数字ID
            Long numericTransactionId = extractTransactionId(transactionId);
            CompleteTransactionResponse response = transactionService.completeTransaction(userId, numericTransactionId, request);
            return ApiResponse.success("交易确认成功", response);
        } catch (Exception e) {
            log.error("Complete transaction failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 取消交易
     */
    @PostMapping("/{transactionId}/cancel")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Void> cancelTransaction(
            @PathVariable String transactionId,
            @Valid @RequestBody CancelTransactionRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            // 从字符串ID中提取数字ID
            Long numericTransactionId = extractTransactionId(transactionId);
            transactionService.cancelTransaction(userId, numericTransactionId, request);
            return ApiResponse.success("交易已取消", null);
        } catch (Exception e) {
            log.error("Cancel transaction failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 获取交易记录
     */
    @GetMapping
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Map<String, Object>> getTransactions(
            @RequestParam(defaultValue = "all") String type,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            Page<TransactionResponse> transactions = transactionService.getTransactions(userId, type, status, page, size);
            
            // 构建响应数据
            Map<String, Object> data = new HashMap<>();
            data.put("transactions", transactions.getContent());
            
            Map<String, Object> pagination = new HashMap<>();
            pagination.put("page", page);
            pagination.put("size", size);
            pagination.put("total", transactions.getTotalElements());
            pagination.put("hasNext", transactions.hasNext());
            data.put("pagination", pagination);
            
            return ApiResponse.success("获取成功", data);
        } catch (Exception e) {
            log.error("Get transactions failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 获取单个交易详情
     */
    @GetMapping("/{transactionId}")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<TransactionResponse> getTransactionDetail(
            @PathVariable String transactionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            // 从字符串ID中提取数字ID
            Long numericTransactionId = extractTransactionId(transactionId);
            TransactionResponse transaction = transactionService.getTransactionDetail(userId, numericTransactionId);
            return ApiResponse.success("获取成功", transaction);
        } catch (Exception e) {
            log.error("Get transaction detail failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 从字符串形式的交易ID中提取数字ID
     * 例如: "tx_1234567890" -> 1234567890
     */
    private Long extractTransactionId(String transactionId) {
        if (transactionId.startsWith("tx_")) {
            try {
                return Long.valueOf(transactionId.substring(3));
            } catch (NumberFormatException e) {
                throw new RuntimeException("无效的交易ID格式: " + transactionId);
            }
        } else {
            // 如果不是tx_开头，尝试直接解析为数字
            try {
                return Long.valueOf(transactionId);
            } catch (NumberFormatException e) {
                throw new RuntimeException("无效的交易ID格式: " + transactionId);
            }
        }
    }
    
    /**
     * 发起交易申请（新接口）
     */
    @PostMapping("/request")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<TransactionRequestResponse> createTransactionRequest(
            @Valid @RequestBody TransactionRequestRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            TransactionRequestResponse response = transactionService.createTransactionRequest(userId, request);
            return ApiResponse.success("交易申请已发送", response);
        } catch (Exception e) {
            log.error("Create transaction request failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 响应交易申请（新接口）
     */
    @PostMapping("/{transactionId}/respond")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<TransactionRespondResponse> respondToTransactionRequest(
            @PathVariable String transactionId,
            @Valid @RequestBody TransactionRespondRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            Long numericTransactionId = extractTransactionId(transactionId);
            TransactionRespondResponse response = transactionService.respondToTransactionRequest(userId, numericTransactionId, request);
            return ApiResponse.success(response.getMessage(), response);
        } catch (Exception e) {
            log.error("Respond to transaction request failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
}