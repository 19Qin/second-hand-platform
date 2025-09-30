package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.AddAddressRequest;
import com.fliliy.secondhand.dto.response.AddressResponse;
import com.fliliy.secondhand.service.AddressService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/user/addresses")
@RequiredArgsConstructor
@Slf4j
public class AddressController {
    
    private final AddressService addressService;
    
    /**
     * 获取用户地址列表
     */
    @GetMapping
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<List<AddressResponse>> getUserAddresses(@AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            List<AddressResponse> addresses = addressService.getUserAddresses(userId);
            return ApiResponse.success("获取成功", addresses);
        } catch (Exception e) {
            log.error("Get user addresses failed", e);
            return ApiResponse.error("获取地址列表失败: " + e.getMessage());
        }
    }
    
    /**
     * 添加新地址
     */
    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<AddressResponse> addAddress(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody AddAddressRequest request) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            AddressResponse address = addressService.addAddress(userId, request);
            return ApiResponse.success("添加成功", address);
        } catch (Exception e) {
            log.error("Add address failed", e);
            return ApiResponse.error("添加地址失败: " + e.getMessage());
        }
    }
    
    /**
     * 更新地址
     */
    @PutMapping("/{addressId}")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<AddressResponse> updateAddress(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long addressId,
            @Valid @RequestBody AddAddressRequest request) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            AddressResponse address = addressService.updateAddress(userId, addressId, request);
            return ApiResponse.success("更新成功", address);
        } catch (Exception e) {
            log.error("Update address failed", e);
            return ApiResponse.error("更新地址失败: " + e.getMessage());
        }
    }
    
    /**
     * 设置默认地址
     */
    @PutMapping("/{addressId}/default")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Object> setDefaultAddress(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long addressId) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            addressService.setDefaultAddress(userId, addressId);
            return ApiResponse.success("设置成功");
        } catch (Exception e) {
            log.error("Set default address failed", e);
            return ApiResponse.error("设置默认地址失败: " + e.getMessage());
        }
    }
    
    /**
     * 删除地址
     */
    @DeleteMapping("/{addressId}")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Object> deleteAddress(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long addressId) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            addressService.deleteAddress(userId, addressId);
            return ApiResponse.success("删除成功");
        } catch (Exception e) {
            log.error("Delete address failed", e);
            return ApiResponse.error("删除地址失败: " + e.getMessage());
        }
    }
}