package com.fliliy.secondhand.service;

import com.fliliy.secondhand.common.ErrorCode;
import com.fliliy.secondhand.dto.request.LoginRequest;
import com.fliliy.secondhand.dto.request.RegisterRequest;
import com.fliliy.secondhand.dto.response.AuthResponse;
import com.fliliy.secondhand.entity.User;
import com.fliliy.secondhand.entity.UserToken;
import com.fliliy.secondhand.entity.VerificationCode;
import com.fliliy.secondhand.repository.UserRepository;
import com.fliliy.secondhand.repository.UserTokenRepository;
import com.fliliy.secondhand.util.IdGenerator;
import com.fliliy.secondhand.util.JwtUtil;
import com.fliliy.secondhand.util.PasswordUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {
    
    private final UserRepository userRepository;
    private final UserTokenRepository userTokenRepository;
    private final SmsService smsService;
    private final JwtUtil jwtUtil;
    
    /**
     * 用户注册
     */
    @Transactional
    public AuthResponse register(RegisterRequest request, HttpServletRequest httpRequest) {
        String mobile = request.getMobile();
        String clientIp = getClientIpAddress(httpRequest);

        log.info("[用户注册] 开始注册流程 - 手机号: {}, IP: {}", mobile, clientIp);

        // 验证参数
        validateRegisterRequest(request);
        log.debug("[用户注册] 参数验证通过 - 手机号: {}", mobile);

        // 验证短信验证码
        boolean isCodeValid = smsService.verifySmsCode(
                request.getMobile(),
                request.getSmsCode(),
                request.getSmsId(),
                VerificationCode.CodeType.REGISTER
        );

        if (!isCodeValid) {
            log.warn("[用户注册] 验证码错误 - 手机号: {}, IP: {}", mobile, clientIp);
            throw new RuntimeException(ErrorCode.SMS_CODE_ERROR.getMessage());
        }
        log.debug("[用户注册] 验证码验证通过 - 手机号: {}", mobile);

        // 检查用户是否已存在
        if (userRepository.existsByMobile(request.getMobile())) {
            log.warn("[用户注册] 用户已存在 - 手机号: {}, IP: {}", mobile, clientIp);
            throw new RuntimeException(ErrorCode.USER_ALREADY_EXISTS.getMessage());
        }

        // 创建用户
        User user = new User();
        user.setId(IdGenerator.generateUserId());
        user.setUsername(request.getUsername());
        user.setMobile(request.getMobile());

        // 加密密码
        String salt = PasswordUtil.generateSalt();
        String passwordHash = PasswordUtil.encode(request.getPassword(), salt);
        user.setSalt(salt);
        user.setPasswordHash(passwordHash);

        userRepository.save(user);
        log.info("[用户注册] 注册成功 - 用户ID: {}, 手机号: {}, 用户名: {}, IP: {}",
                user.getId(), mobile, request.getUsername(), clientIp);

        // 生成令牌
        return generateAuthResponse(user, httpRequest);
    }
    
    /**
     * 密码登录
     */
    @Transactional
    public AuthResponse loginWithPassword(LoginRequest request, HttpServletRequest httpRequest) {
        String mobile = request.getMobile();
        String clientIp = getClientIpAddress(httpRequest);

        log.info("[密码登录] 登录请求 - 手机号: {}, IP: {}", mobile, clientIp);

        // 查找用户
        Optional<User> optionalUser = userRepository.findByMobile(request.getMobile());
        if (!optionalUser.isPresent()) {
            log.warn("[密码登录] 用户不存在 - 手机号: {}, IP: {}", mobile, clientIp);
            throw new RuntimeException(ErrorCode.USER_NOT_EXISTS.getMessage());
        }

        User user = optionalUser.get();

        // 检查账号状态
        checkAccountStatus(user);

        // 验证密码
        if (!PasswordUtil.matches(request.getPassword(), user.getSalt(), user.getPasswordHash())) {
            log.warn("[密码登录] 密码错误 - 用户ID: {}, 手机号: {}, 失败次数: {}, IP: {}",
                    user.getId(), mobile, user.getLoginAttempts() + 1, clientIp);
            handleLoginFailure(user);
            throw new RuntimeException(ErrorCode.PASSWORD_INCORRECT.getMessage());
        }

        // 登录成功，重置失败次数
        handleLoginSuccess(user, httpRequest);
        log.info("[密码登录] 登录成功 - 用户ID: {}, 手机号: {}, 用户名: {}, IP: {}",
                user.getId(), mobile, user.getUsername(), clientIp);

        return generateAuthResponse(user, httpRequest);
    }
    
    /**
     * 验证码登录
     */
    @Transactional
    public AuthResponse loginWithSms(LoginRequest request, HttpServletRequest httpRequest) {
        // 验证短信验证码
        boolean isCodeValid = smsService.verifySmsCode(
                request.getMobile(), 
                request.getSmsCode(), 
                request.getSmsId(), 
                VerificationCode.CodeType.LOGIN
        );
        
        if (!isCodeValid) {
            throw new RuntimeException(ErrorCode.SMS_CODE_ERROR.getMessage());
        }
        
        // 查找用户
        Optional<User> optionalUser = userRepository.findByMobile(request.getMobile());
        if (!optionalUser.isPresent()) {
            throw new RuntimeException(ErrorCode.USER_NOT_EXISTS.getMessage());
        }
        
        User user = optionalUser.get();
        
        // 检查账号状态
        checkAccountStatus(user);
        
        // 登录成功
        handleLoginSuccess(user, httpRequest);
        
        return generateAuthResponse(user, httpRequest);
    }
    
    /**
     * 刷新令牌
     */
    @Transactional
    public AuthResponse refreshToken(String refreshToken, HttpServletRequest httpRequest) {
        // 验证刷新令牌
        Optional<UserToken> optionalToken = userTokenRepository
                .findByRefreshTokenAndRevokedFalseAndExpiresAtAfter(refreshToken, LocalDateTime.now());
        
        if (!optionalToken.isPresent()) {
            throw new RuntimeException(ErrorCode.TOKEN_INVALID.getMessage());
        }
        
        UserToken userToken = optionalToken.get();
        
        // 查找用户
        Optional<User> optionalUser = userRepository.findById(userToken.getUserId());
        if (!optionalUser.isPresent()) {
            throw new RuntimeException(ErrorCode.USER_NOT_EXISTS.getMessage());
        }
        
        User user = optionalUser.get();
        
        // 检查账号状态
        checkAccountStatus(user);
        
        // 撤销旧的刷新令牌
        userToken.setRevoked(true);
        userTokenRepository.save(userToken);
        
        // 生成新的令牌
        return generateAuthResponse(user, httpRequest);
    }
    
    /**
     * 退出登录
     */
    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken != null && !refreshToken.isEmpty()) {
            userTokenRepository.revokeByRefreshToken(refreshToken);
            log.info("[退出登录] 用户退出登录 - RefreshToken已撤销");
        }
    }

    /**
     * 退出所有设备
     */
    @Transactional
    public void logoutAll(Long userId) {
        userTokenRepository.revokeAllByUserId(userId);
        log.info("[退出所有设备] 用户退出所有设备 - 用户ID: {}", userId);
    }
    
    private void validateRegisterRequest(RegisterRequest request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException(ErrorCode.PASSWORD_NOT_MATCH.getMessage());
        }
        
        if (!request.getAgreeTerms()) {
            throw new RuntimeException(ErrorCode.TERMS_NOT_AGREED.getMessage());
        }
        
        if (!PasswordUtil.isValidPassword(request.getPassword())) {
            throw new RuntimeException(ErrorCode.PASSWORD_FORMAT_ERROR.getMessage());
        }
    }
    
    private void checkAccountStatus(User user) {
        if (user.getStatus() == 0) {
            throw new RuntimeException("账号已被禁用");
        }
        
        if (user.getStatus() == 2) {
            throw new RuntimeException(ErrorCode.ACCOUNT_LOCKED.getMessage());
        }
    }
    
    private void handleLoginFailure(User user) {
        int attempts = user.getLoginAttempts() + 1;
        userRepository.updateLoginAttempts(user.getId(), attempts);

        if (attempts >= 5) {
            // 锁定账号
            user.setStatus(2);
            userRepository.save(user);
            log.warn("[账号安全] 账号已锁定 - 用户ID: {}, 手机号: {}, 原因: 登录失败次数过多({}次)",
                    user.getId(), user.getMobile(), attempts);
            throw new RuntimeException(ErrorCode.LOGIN_ATTEMPTS_EXCEEDED.getMessage());
        }
    }
    
    private void handleLoginSuccess(User user, HttpServletRequest request) {
        String clientIp = getClientIpAddress(request);
        userRepository.updateLastLogin(user.getId(), LocalDateTime.now(), clientIp);
    }
    
    private AuthResponse generateAuthResponse(User user, HttpServletRequest request) {
        String userId = String.valueOf(user.getId());
        
        // 生成JWT令牌
        String accessToken = jwtUtil.generateAccessToken(userId, user.getMobile());
        String refreshToken = jwtUtil.generateRefreshToken(userId);
        
        // 保存刷新令牌
        UserToken userToken = new UserToken();
        userToken.setUserId(user.getId());
        userToken.setRefreshToken(refreshToken);
        userToken.setDeviceId(IdGenerator.generateDeviceId());
        userToken.setIpAddress(getClientIpAddress(request));
        userToken.setUserAgent(request.getHeader("User-Agent"));
        userToken.setExpiresAt(LocalDateTime.now().plusDays(jwtUtil.getRefreshTokenExpireSeconds() / (24 * 60 * 60)));
        
        userTokenRepository.save(userToken);
        
        // 构建响应
        AuthResponse response = new AuthResponse();
        response.setUserId(userId);
        response.setUsername(user.getUsername());
        response.setMobile(user.getMobile());
        response.setEmail(user.getEmail());
        response.setAvatar(user.getAvatar());
        response.setAccessToken(accessToken);
        response.setRefreshToken(refreshToken);
        response.setExpiresIn(jwtUtil.getAccessTokenExpireSeconds());
        
        return response;
    }
    
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }
}