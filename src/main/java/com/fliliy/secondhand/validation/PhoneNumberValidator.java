package com.fliliy.secondhand.validation;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import java.util.regex.Pattern;

/**
 * 手机号校验器
 * 校验中国大陆手机号格式: 1开头的11位数字
 * 校验澳洲手机号格式:
 *   - 0412345678 (10位,04或05开头)
 *   - 04XX XXX XXX (带空格)
 *   - +61 4XX XXX XXX (国际格式带空格)
 *   - +61412345678 (国际格式无空格)
 */
public class PhoneNumberValidator implements ConstraintValidator<ValidPhoneNumber, String> {

    // 中国大陆手机号正则: 1开头的11位数字
    private static final Pattern CHINA_PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");
    // 澳洲手机号正则: 04或05开头的10位数字(无空格)
    private static final Pattern AUSTRALIA_PHONE_PATTERN = Pattern.compile("^0[45]\\d{8}$");
    // 澳洲手机号正则: +61开头的国际格式(无空格)
    private static final Pattern AUSTRALIA_INTL_PATTERN = Pattern.compile("^\\+61[45]\\d{8}$");

    @Override
    public void initialize(ValidPhoneNumber constraintAnnotation) {
        // 初始化逻辑(可选)
    }

    @Override
    public boolean isValid(String phone, ConstraintValidatorContext context) {
        // null值由@NotNull/@NotBlank处理,这里认为null是valid的
        if (phone == null || phone.isEmpty()) {
            return true;
        }

        // 移除所有空格,统一处理
        String cleanPhone = phone.replaceAll("\\s+", "");

        // 验证中国或澳洲手机号
        return CHINA_PHONE_PATTERN.matcher(cleanPhone).matches() ||
               AUSTRALIA_PHONE_PATTERN.matcher(cleanPhone).matches() ||
               AUSTRALIA_INTL_PATTERN.matcher(cleanPhone).matches();
    }
}
