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
            @PathVariable Long transactionId,
            @Valid @RequestBody AgreeOfflineRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            AgreeOfflineResponse response = transactionService.agreeOfflineTransaction(userId, transactionId, request);
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
            @PathVariable Long transactionId,
            @Valid @RequestBody CompleteTransactionRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            CompleteTransactionResponse response = transactionService.completeTransaction(userId, transactionId, request);
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
            @PathVariable Long transactionId,
            @Valid @RequestBody CancelTransactionRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            transactionService.cancelTransaction(userId, transactionId, request);
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
            @PathVariable Long transactionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            // 这里可以扩展实现单个交易详情获取
            return ApiResponse.success("获取成功", null);
        } catch (Exception e) {
            log.error("Get transaction detail failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
}