package com.fliliy.secondhand.dto.response;

import lombok.Data;

@Data
public class AuthResponse {
    
    private String userId;
    private String username;
    private String mobile;
    private String email;
    private String avatar;
    private String accessToken;
    private String refreshToken;
    private Long expiresIn;
    private Boolean needBindMobile = false;
}