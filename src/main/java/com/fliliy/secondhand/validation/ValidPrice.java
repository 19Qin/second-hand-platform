package com.fliliy.secondhand.validation;

import javax.validation.Constraint;
import javax.validation.Payload;
import java.lang.annotation.*;

/**
 * 价格校验注解
 * 用于校验价格格式(大于0,最多2位小数)
 */
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Constraint(validatedBy = PriceValidator.class)
public @interface ValidPrice {

    String message() default "价格格式不正确,必须大于0且最多2位小数";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    /**
     * 最小价格(默认0.01)
     */
    double min() default 0.01;

    /**
     * 最大价格(默认100000000)
     */
    double max() default 100000000.0;
}
