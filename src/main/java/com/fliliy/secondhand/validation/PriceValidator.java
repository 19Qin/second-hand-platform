package com.fliliy.secondhand.validation;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import java.math.BigDecimal;

/**
 * 价格校验器
 * 校验价格范围和小数位数
 */
public class PriceValidator implements ConstraintValidator<ValidPrice, Number> {

    private double min;
    private double max;

    @Override
    public void initialize(ValidPrice constraintAnnotation) {
        this.min = constraintAnnotation.min();
        this.max = constraintAnnotation.max();
    }

    @Override
    public boolean isValid(Number value, ConstraintValidatorContext context) {
        // null值由@NotNull处理
        if (value == null) {
            return true;
        }

        double price = value.doubleValue();

        // 检查范围
        if (price < min || price > max) {
            return false;
        }

        // 检查小数位数(最多2位)
        BigDecimal bd = BigDecimal.valueOf(price);
        int scale = bd.scale();

        return scale <= 2;
    }
}
