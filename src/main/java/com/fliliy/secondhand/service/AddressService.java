package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.request.AddAddressRequest;
import com.fliliy.secondhand.dto.response.AddressResponse;
import com.fliliy.secondhand.entity.UserAddress;
import com.fliliy.secondhand.repository.UserAddressRepository;
import com.fliliy.secondhand.util.IdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AddressService {
    
    private final UserAddressRepository userAddressRepository;
    private final IdGenerator idGenerator;
    
    /**
     * 获取用户地址列表
     */
    public List<AddressResponse> getUserAddresses(Long userId) {
        List<UserAddress> addresses = userAddressRepository.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId);
        return addresses.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * 添加新地址
     */
    @Transactional
    public AddressResponse addAddress(Long userId, AddAddressRequest request) {
        // 如果设置为默认地址，先清除其他默认地址
        if (Boolean.TRUE.equals(request.getIsDefault())) {
            userAddressRepository.clearDefaultAddressByUserId(userId);
        }
        
        UserAddress address = new UserAddress();
        address.setId(idGenerator.generateId());
        address.setUserId(userId);
        address.setContactName(request.getContactName());
        address.setContactPhone(request.getContactPhone());
        address.setProvince(request.getProvince());
        address.setCity(request.getCity());
        address.setDistrict(request.getDistrict());
        address.setDetailAddress(request.getDetailAddress());
        address.setLongitude(request.getLongitude());
        address.setLatitude(request.getLatitude());
        address.setIsDefault(request.getIsDefault());
        
        UserAddress savedAddress = userAddressRepository.save(address);
        return convertToResponse(savedAddress);
    }
    
    /**
     * 设置默认地址
     */
    @Transactional
    public void setDefaultAddress(Long userId, Long addressId) {
        // 验证地址是否属于当前用户
        UserAddress address = userAddressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("地址不存在"));
        
        if (!address.getUserId().equals(userId)) {
            throw new RuntimeException("无权限操作此地址");
        }
        
        // 清除其他默认地址
        userAddressRepository.clearDefaultAddressByUserId(userId);
        
        // 设置新的默认地址
        address.setIsDefault(true);
        userAddressRepository.save(address);
    }
    
    /**
     * 更新地址
     */
    @Transactional
    public AddressResponse updateAddress(Long userId, Long addressId, AddAddressRequest request) {
        UserAddress address = userAddressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("地址不存在"));
        
        if (!address.getUserId().equals(userId)) {
            throw new RuntimeException("无权限操作此地址");
        }
        
        // 如果设置为默认地址，先清除其他默认地址
        if (Boolean.TRUE.equals(request.getIsDefault()) && !Boolean.TRUE.equals(address.getIsDefault())) {
            userAddressRepository.clearDefaultAddressByUserId(userId);
        }
        
        address.setContactName(request.getContactName());
        address.setContactPhone(request.getContactPhone());
        address.setProvince(request.getProvince());
        address.setCity(request.getCity());
        address.setDistrict(request.getDistrict());
        address.setDetailAddress(request.getDetailAddress());
        address.setLongitude(request.getLongitude());
        address.setLatitude(request.getLatitude());
        address.setIsDefault(request.getIsDefault());
        
        UserAddress savedAddress = userAddressRepository.save(address);
        return convertToResponse(savedAddress);
    }
    
    /**
     * 删除地址
     */
    @Transactional
    public void deleteAddress(Long userId, Long addressId) {
        UserAddress address = userAddressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("地址不存在"));
        
        if (!address.getUserId().equals(userId)) {
            throw new RuntimeException("无权限操作此地址");
        }
        
        if (Boolean.TRUE.equals(address.getIsDefault())) {
            throw new RuntimeException("默认地址不能删除，请先设置其他地址为默认地址");
        }
        
        userAddressRepository.delete(address);
    }
    
    /**
     * 使用地址（增加使用次数）
     */
    @Transactional
    public void useAddress(Long addressId) {
        userAddressRepository.incrementUsageCount(addressId);
    }
    
    private AddressResponse convertToResponse(UserAddress address) {
        AddressResponse response = new AddressResponse();
        response.setId(address.getId());
        response.setContactName(address.getContactName());
        response.setContactPhone(address.getContactPhone());
        response.setProvince(address.getProvince());
        response.setCity(address.getCity());
        response.setDistrict(address.getDistrict());
        response.setDetailAddress(address.getDetailAddress());
        response.setLongitude(address.getLongitude());
        response.setLatitude(address.getLatitude());
        response.setIsDefault(address.getIsDefault());
        response.setUsageCount(address.getUsageCount());
        response.setCreatedAt(address.getCreatedAt());
        response.setLastUsedAt(address.getLastUsedAt());
        return response;
    }
}