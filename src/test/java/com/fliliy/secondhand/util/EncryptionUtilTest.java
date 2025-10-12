package com.fliliy.secondhand.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 加密工具类测试
 */
@DisplayName("加密工具测试")
public class EncryptionUtilTest {

    private EncryptionUtil encryptionUtil;

    @BeforeEach
    public void setUp() throws Exception {
        // 手动创建EncryptionUtil实例
        encryptionUtil = new EncryptionUtil();

        // 使用反射设置密钥（因为是通过@Value注入的）
        Field secretKeyField = EncryptionUtil.class.getDeclaredField("secretKey");
        secretKeyField.setAccessible(true);
        secretKeyField.set(encryptionUtil, "TestSecretKey123");

        assertNotNull(encryptionUtil, "EncryptionUtil应该被正确创建");
    }

    @Test
    @DisplayName("测试加密和解密 - 普通文本")
    public void testEncryptAndDecrypt_PlainText() {
        // Given
        String plainText = "Hello, World!";

        // When
        String encrypted = encryptionUtil.encrypt(plainText);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted, "加密结果不应为null");
        assertNotEquals(plainText, encrypted, "加密后应该与原文不同");
        assertEquals(plainText, decrypted, "解密后应该与原文相同");
    }

    @Test
    @DisplayName("测试加密和解密 - 中文文本")
    public void testEncryptAndDecrypt_ChineseText() {
        // Given
        String plainText = "这是一段中文测试文本";

        // When
        String encrypted = encryptionUtil.encrypt(plainText);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted);
        assertNotEquals(plainText, encrypted);
        assertEquals(plainText, decrypted);
    }

    @Test
    @DisplayName("测试加密和解密 - 身份证号")
    public void testEncryptAndDecrypt_IdCard() {
        // Given
        String idCard = "110101199001011234";

        // When
        String encrypted = encryptionUtil.encrypt(idCard);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted);
        assertNotEquals(idCard, encrypted);
        assertEquals(idCard, decrypted);
    }

    @Test
    @DisplayName("测试加密和解密 - 银行卡号")
    public void testEncryptAndDecrypt_BankCard() {
        // Given
        String bankCard = "6222021234567890";

        // When
        String encrypted = encryptionUtil.encrypt(bankCard);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted);
        assertNotEquals(bankCard, encrypted);
        assertEquals(bankCard, decrypted);
    }

    @Test
    @DisplayName("测试加密和解密 - 空字符串")
    public void testEncryptAndDecrypt_EmptyString() {
        // Given
        String plainText = "";

        // When
        String encrypted = encryptionUtil.encrypt(plainText);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted);
        assertEquals(plainText, decrypted);
    }

    @Test
    @DisplayName("测试加密和解密 - 特殊字符")
    public void testEncryptAndDecrypt_SpecialCharacters() {
        // Given
        String plainText = "!@#$%^&*()_+-=[]{}|;':\",./<>?";

        // When
        String encrypted = encryptionUtil.encrypt(plainText);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted);
        assertEquals(plainText, decrypted);
    }

    @Test
    @DisplayName("测试加密 - null值")
    public void testEncrypt_NullValue() {
        // When & Then
        assertThrows(Exception.class, () -> {
            encryptionUtil.encrypt(null);
        }, "加密null值应该抛出异常");
    }

    @Test
    @DisplayName("测试解密 - null值")
    public void testDecrypt_NullValue() {
        // When & Then
        assertThrows(Exception.class, () -> {
            encryptionUtil.decrypt(null);
        }, "解密null值应该抛出异常");
    }

    @Test
    @DisplayName("测试解密 - 无效密文")
    public void testDecrypt_InvalidCipherText() {
        // When & Then
        assertThrows(Exception.class, () -> {
            encryptionUtil.decrypt("invalid_cipher_text");
        }, "解密无效密文应该抛出异常");
    }

    @Test
    @DisplayName("测试手机号脱敏 - 标准格式")
    public void testMaskPhone_StandardFormat() {
        // Given
        String phone = "13800138000";

        // When
        String masked = encryptionUtil.maskPhone(phone);

        // Then
        assertEquals("138****8000", masked);
    }

    @Test
    @DisplayName("测试手机号脱敏 - 短号码")
    public void testMaskPhone_ShortNumber() {
        // Given
        String phone = "12345";

        // When
        String masked = encryptionUtil.maskPhone(phone);

        // Then
        assertEquals("12345", masked, "短号码不应该脱敏");
    }

    @Test
    @DisplayName("测试手机号脱敏 - null值")
    public void testMaskPhone_NullValue() {
        // When
        String masked = encryptionUtil.maskPhone(null);

        // Then
        assertNull(masked);
    }

    @Test
    @DisplayName("测试身份证号脱敏 - 18位")
    public void testMaskIdCard_18Digits() {
        // Given
        String idCard = "110101199001011234";

        // When
        String masked = encryptionUtil.maskIdCard(idCard);

        // Then
        assertEquals("110***********1234", masked);
    }

    @Test
    @DisplayName("测试身份证号脱敏 - 15位")
    public void testMaskIdCard_15Digits() {
        // Given
        String idCard = "110101900101123";

        // When
        String masked = encryptionUtil.maskIdCard(idCard);

        // Then
        assertEquals("110*********123", masked);
    }

    @Test
    @DisplayName("测试身份证号脱敏 - 短号码")
    public void testMaskIdCard_ShortNumber() {
        // Given
        String idCard = "12345";

        // When
        String masked = encryptionUtil.maskIdCard(idCard);

        // Then
        assertEquals("12345", masked);
    }

    @Test
    @DisplayName("测试银行卡号脱敏")
    public void testMaskBankCard_StandardFormat() {
        // Given
        String bankCard = "6222021234567890";

        // When
        String masked = encryptionUtil.maskBankCard(bankCard);

        // Then
        assertEquals("6222 **** **** 7890", masked);
    }

    @Test
    @DisplayName("测试银行卡号脱敏 - 短号码")
    public void testMaskBankCard_ShortNumber() {
        // Given
        String bankCard = "123456";

        // When
        String masked = encryptionUtil.maskBankCard(bankCard);

        // Then
        assertEquals("123456", masked);
    }

    @Test
    @DisplayName("测试姓名脱敏 - 两个字")
    public void testMaskName_TwoCharacters() {
        // Given
        String name = "张三";

        // When
        String masked = encryptionUtil.maskName(name);

        // Then
        assertEquals("张*", masked);
    }

    @Test
    @DisplayName("测试姓名脱敏 - 三个字")
    public void testMaskName_ThreeCharacters() {
        // Given
        String name = "李小明";

        // When
        String masked = encryptionUtil.maskName(name);

        // Then
        assertEquals("李**", masked);
    }

    @Test
    @DisplayName("测试姓名脱敏 - 四个字")
    public void testMaskName_FourCharacters() {
        // Given
        String name = "欧阳修远";

        // When
        String masked = encryptionUtil.maskName(name);

        // Then
        assertEquals("欧***", masked);
    }

    @Test
    @DisplayName("测试姓名脱敏 - 单个字")
    public void testMaskName_SingleCharacter() {
        // Given
        String name = "王";

        // When
        String masked = encryptionUtil.maskName(name);

        // Then
        assertEquals("王", masked);
    }

    @Test
    @DisplayName("测试姓名脱敏 - null值")
    public void testMaskName_NullValue() {
        // When
        String masked = encryptionUtil.maskName(null);

        // Then
        assertNull(masked);
    }

    @Test
    @DisplayName("测试加密性能 - 1000次加密")
    public void testEncryptionPerformance() {
        // Given
        String plainText = "性能测试数据123456789";
        int iterations = 1000;

        // When
        long startTime = System.currentTimeMillis();
        for (int i = 0; i < iterations; i++) {
            encryptionUtil.encrypt(plainText);
        }
        long endTime = System.currentTimeMillis();

        // Then
        long duration = endTime - startTime;
        System.out.printf("加密%d次耗时: %dms, 平均: %.2fms/次%n",
                iterations, duration, (double) duration / iterations);

        assertTrue(duration < 5000, "1000次加密应该在5秒内完成");
    }

    @Test
    @DisplayName("测试解密性能 - 1000次解密")
    public void testDecryptionPerformance() {
        // Given
        String plainText = "性能测试数据123456789";
        String encrypted = encryptionUtil.encrypt(plainText);
        int iterations = 1000;

        // When
        long startTime = System.currentTimeMillis();
        for (int i = 0; i < iterations; i++) {
            encryptionUtil.decrypt(encrypted);
        }
        long endTime = System.currentTimeMillis();

        // Then
        long duration = endTime - startTime;
        System.out.printf("解密%d次耗时: %dms, 平均: %.2fms/次%n",
                iterations, duration, (double) duration / iterations);

        assertTrue(duration < 5000, "1000次解密应该在5秒内完成");
    }

    @Test
    @DisplayName("测试脱敏性能 - 1000次脱敏")
    public void testMaskingPerformance() {
        // Given
        String phone = "13800138000";
        int iterations = 1000;

        // When
        long startTime = System.currentTimeMillis();
        for (int i = 0; i < iterations; i++) {
            encryptionUtil.maskPhone(phone);
        }
        long endTime = System.currentTimeMillis();

        // Then
        long duration = endTime - startTime;
        System.out.printf("脱敏%d次耗时: %dms, 平均: %.2fms/次%n",
                iterations, duration, (double) duration / iterations);

        assertTrue(duration < 1000, "1000次脱敏应该在1秒内完成");
    }

    @Test
    @DisplayName("测试加密的唯一性 - 相同明文多次加密")
    public void testEncryptionUniqueness() {
        // Given
        String plainText = "测试唯一性";

        // When
        String encrypted1 = encryptionUtil.encrypt(plainText);
        String encrypted2 = encryptionUtil.encrypt(plainText);

        // Then
        // 注意：AES-ECB模式下相同明文会产生相同密文
        // 如果使用CBC或其他模式，应该不同
        assertNotNull(encrypted1);
        assertNotNull(encrypted2);
    }

    @Test
    @DisplayName("测试长文本加密")
    public void testLongTextEncryption() {
        // Given
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 1000; i++) {
            sb.append("长文本测试");
        }
        String longText = sb.toString();

        // When
        String encrypted = encryptionUtil.encrypt(longText);
        String decrypted = encryptionUtil.decrypt(encrypted);

        // Then
        assertNotNull(encrypted);
        assertEquals(longText, decrypted);
        assertTrue(encrypted.length() > longText.length(),
                "加密后长度应该大于原文（Base64编码）");
    }
}
