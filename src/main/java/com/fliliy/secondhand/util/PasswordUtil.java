package com.fliliy.secondhand.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.security.SecureRandom;

public class PasswordUtil {
    
    private static final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    private static final SecureRandom secureRandom = new SecureRandom();
    private static final String CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    
    /**
     * 生成盐值
     */
    public static String generateSalt() {
        StringBuilder salt = new StringBuilder();
        for (int i = 0; i < 16; i++) {
            salt.append(CHARACTERS.charAt(secureRandom.nextInt(CHARACTERS.length())));
        }
        return salt.toString();
    }
    
    /**
     * 加密密码
     */
    public static String encode(String rawPassword, String salt) {
        return encoder.encode(rawPassword + salt);
    }
    
    /**
     * 验证密码
     */
    public static boolean matches(String rawPassword, String salt, String encodedPassword) {
        return encoder.matches(rawPassword + salt, encodedPassword);
    }
    
    /**
     * 验证密码强度
     */
    public static boolean isValidPassword(String password) {
        if (password == null || password.length() < 8) {
            return false;
        }
        
        boolean hasLetter = false;
        boolean hasDigit = false;
        
        for (char c : password.toCharArray()) {
            if (Character.isLetter(c)) {
                hasLetter = true;
            } else if (Character.isDigit(c)) {
                hasDigit = true;
            }
        }
        
        return hasLetter && hasDigit;
    }
}