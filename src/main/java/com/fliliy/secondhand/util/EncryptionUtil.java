package com.fliliy.secondhand.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * 加密工具类
 * 用于敏感数据的加密和解密
 */
@Slf4j
@Component
public class EncryptionUtil {

    @Value("${app.encryption.key:FliliySecretKey16}")
    private String secretKey;

    private static final String ALGORITHM = "AES";

    /**
     * 加密
     *
     * @param plainText 明文
     * @return 密文（Base64编码）
     */
    public String encrypt(String plainText) {
        if (plainText == null || plainText.isEmpty()) {
            return plainText;
        }

        try {
            SecretKeySpec keySpec = generateKey();
            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec);

            byte[] encrypted = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(encrypted);

        } catch (Exception e) {
            log.error("[加密] 加密失败 - 原因: {}", e.getMessage(), e);
            throw new RuntimeException("数据加密失败", e);
        }
    }

    /**
     * 解密
     *
     * @param encryptedText 密文（Base64编码）
     * @return 明文
     */
    public String decrypt(String encryptedText) {
        if (encryptedText == null || encryptedText.isEmpty()) {
            return encryptedText;
        }

        try {
            SecretKeySpec keySpec = generateKey();
            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.DECRYPT_MODE, keySpec);

            byte[] decoded = Base64.getDecoder().decode(encryptedText);
            byte[] decrypted = cipher.doFinal(decoded);
            return new String(decrypted, StandardCharsets.UTF_8);

        } catch (Exception e) {
            log.error("[解密] 解密失败 - 原因: {}", e.getMessage(), e);
            throw new RuntimeException("数据解密失败", e);
        }
    }

    /**
     * 手机号脱敏
     *
     * @param phone 手机号
     * @return 脱敏后的手机号（138****8000）
     */
    public String maskPhone(String phone) {
        if (phone == null || phone.length() != 11) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(7);
    }

    /**
     * 身份证号脱敏
     *
     * @param idCard 身份证号
     * @return 脱敏后的身份证号（110***********1234）
     */
    public String maskIdCard(String idCard) {
        if (idCard == null || idCard.length() < 8) {
            return idCard;
        }
        return idCard.substring(0, 3) + "***********" + idCard.substring(idCard.length() - 4);
    }

    /**
     * 银行卡号脱敏
     *
     * @param bankCard 银行卡号
     * @return 脱敏后的银行卡号（6222 **** **** 1234）
     */
    public String maskBankCard(String bankCard) {
        if (bankCard == null || bankCard.length() < 8) {
            return bankCard;
        }
        return bankCard.substring(0, 4) + " **** **** " + bankCard.substring(bankCard.length() - 4);
    }

    /**
     * 姓名脱敏
     *
     * @param name 姓名
     * @return 脱敏后的姓名（张*）
     */
    public String maskName(String name) {
        if (name == null || name.isEmpty()) {
            return name;
        }
        if (name.length() == 1) {
            return name;
        }
        StringBuilder masked = new StringBuilder();
        masked.append(name.charAt(0));
        for (int i = 1; i < name.length(); i++) {
            masked.append("*");
        }
        return masked.toString();
    }

    /**
     * 生成密钥
     */
    private SecretKeySpec generateKey() throws Exception {
        // 确保密钥长度为16字节（AES-128）
        String key = secretKey;
        if (key.length() < 16) {
            StringBuilder paddedKey = new StringBuilder(key);
            for (int i = key.length(); i < 16; i++) {
                paddedKey.append("0");
            }
            key = paddedKey.toString();
        } else if (key.length() > 16) {
            key = key.substring(0, 16);
        }
        return new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), ALGORITHM);
    }
}
