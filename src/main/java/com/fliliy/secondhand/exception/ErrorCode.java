package com.fliliy.secondhand.exception;

import lombok.Getter;

/**
 * 错误码枚举
 * 统一定义所有业务错误码
 */
@Getter
public enum ErrorCode {

    // ==================== 系统错误 1xxx ====================
    SUCCESS(200, "操作成功"),
    SYSTEM_ERROR(1000, "系统内部错误"),
    PARAM_ERROR(1001, "参数错误"),
    PARAM_MISSING(1002, "缺少必需参数"),
    PARAM_TYPE_ERROR(1003, "参数类型错误"),
    REQUEST_METHOD_ERROR(1004, "请求方法不支持"),
    DATABASE_ERROR(1005, "数据库操作失败"),
    REDIS_ERROR(1006, "Redis操作失败"),
    FILE_IO_ERROR(1007, "文件IO错误"),
    NETWORK_ERROR(1008, "网络请求失败"),
    JSON_PARSE_ERROR(1009, "JSON解析错误"),

    // ==================== 认证授权错误 2xxx ====================
    UNAUTHORIZED(2000, "未授权,请先登录"),
    TOKEN_MISSING(2001, "Token缺失"),
    TOKEN_INVALID(2002, "Token无效"),
    TOKEN_EXPIRED(2003, "Token已过期"),
    PERMISSION_DENIED(2004, "权限不足"),
    LOGIN_FAILED(2005, "用户名或密码错误"),
    ACCOUNT_DISABLED(2006, "账号已被禁用"),
    ACCOUNT_LOCKED(2007, "账号已被锁定"),
    PASSWORD_ERROR(2008, "密码错误"),
    OLD_PASSWORD_ERROR(2009, "原密码错误"),

    // ==================== 用户错误 20xx ====================
    USER_NOT_FOUND(2010, "用户不存在"),
    USER_ALREADY_EXISTS(2011, "用户已存在"),
    PHONE_ALREADY_EXISTS(2012, "手机号已被注册"),
    EMAIL_ALREADY_EXISTS(2013, "邮箱已被注册"),
    USERNAME_ALREADY_EXISTS(2014, "用户名已被使用"),
    USER_PROFILE_NOT_FOUND(2015, "用户资料不存在"),
    INVALID_PHONE_NUMBER(2016, "手机号格式不正确"),
    INVALID_EMAIL(2017, "邮箱格式不正确"),
    PASSWORD_TOO_WEAK(2018, "密码强度不足"),
    SAME_PASSWORD(2019, "新密码不能与旧密码相同"),

    // ==================== 验证码错误 21xx ====================
    SMS_CODE_ERROR(2100, "验证码错误"),
    SMS_CODE_EXPIRED(2101, "验证码已过期"),
    SMS_CODE_NOT_FOUND(2102, "验证码不存在"),
    SMS_SEND_FAILED(2103, "验证码发送失败"),
    SMS_SEND_TOO_FREQUENT(2104, "验证码发送过于频繁"),
    SMS_DAILY_LIMIT_EXCEEDED(2105, "今日验证码发送次数已达上限"),

    // ==================== 商品错误 3xxx ====================
    PRODUCT_NOT_FOUND(3000, "商品不存在"),
    PRODUCT_ALREADY_SOLD(3001, "商品已售出"),
    PRODUCT_OFF_SHELF(3002, "商品已下架"),
    PRODUCT_DELETED(3003, "商品已被删除"),
    PRODUCT_TITLE_EMPTY(3004, "商品标题不能为空"),
    PRODUCT_PRICE_INVALID(3005, "商品价格不合法"),
    PRODUCT_CATEGORY_INVALID(3006, "商品分类不存在"),
    PRODUCT_IMAGE_REQUIRED(3007, "至少需要上传一张商品图片"),
    PRODUCT_IMAGE_LIMIT(3008, "商品图片数量超过限制"),
    PRODUCT_DESCRIPTION_TOO_LONG(3009, "商品描述过长"),
    PRODUCT_NOT_OWNER(3010, "您不是该商品的所有者"),
    PRODUCT_CANNOT_BUY_OWN(3011, "不能购买自己的商品"),
    PRODUCT_STATUS_INVALID(3012, "商品状态不正确"),

    // ==================== 分类错误 31xx ====================
    CATEGORY_NOT_FOUND(3100, "分类不存在"),
    CATEGORY_NAME_EXISTS(3101, "分类名称已存在"),
    CATEGORY_HAS_CHILDREN(3102, "该分类下存在子分类,无法删除"),
    CATEGORY_HAS_PRODUCTS(3103, "该分类下存在商品,无法删除"),
    PARENT_CATEGORY_NOT_FOUND(3104, "父分类不存在"),
    CATEGORY_LEVEL_EXCEEDED(3105, "分类层级超过限制"),

    // ==================== 收藏错误 32xx ====================
    FAVORITE_NOT_FOUND(3200, "收藏记录不存在"),
    FAVORITE_ALREADY_EXISTS(3201, "已收藏该商品"),
    CANNOT_FAVORITE_OWN_PRODUCT(3202, "不能收藏自己的商品"),

    // ==================== 交易错误 4xxx ====================
    TRANSACTION_NOT_FOUND(4000, "交易记录不存在"),
    TRANSACTION_ALREADY_EXISTS(4001, "该商品已有待处理的交易"),
    TRANSACTION_STATUS_ERROR(4002, "交易状态不正确"),
    TRANSACTION_NOT_PARTICIPANT(4003, "您不是该交易的参与者"),
    TRANSACTION_CANNOT_CANCEL(4004, "当前状态不允许取消交易"),
    TRANSACTION_CANNOT_COMPLETE(4005, "当前状态不允许完成交易"),
    TRANSACTION_CODE_ERROR(4006, "交易码错误"),
    TRANSACTION_CODE_EXPIRED(4007, "交易码已过期"),
    TRANSACTION_ALREADY_COMPLETED(4008, "交易已完成"),
    TRANSACTION_ALREADY_CANCELLED(4009, "交易已取消"),
    BUYER_SAME_AS_SELLER(4010, "买家和卖家不能是同一人"),
    TRANSACTION_PRICE_MISMATCH(4011, "交易价格与商品价格不符"),
    OFFLINE_MEETING_NOT_SET(4012, "线下见面信息未设置"),
    OFFLINE_MEETING_NOT_AGREED(4013, "双方尚未同意线下见面"),
    TRANSACTION_CODE_NOT_FOUND(4014, "交易码不存在"),

    // ==================== 聊天错误 5xxx ====================
    CHAT_ROOM_NOT_FOUND(5000, "聊天室不存在"),
    CHAT_MESSAGE_NOT_FOUND(5001, "聊天消息不存在"),
    CHAT_ROOM_ACCESS_DENIED(5002, "无权访问该聊天室"),
    CHAT_MESSAGE_EMPTY(5003, "消息内容不能为空"),
    CHAT_MESSAGE_TOO_LONG(5004, "消息内容过长"),
    CHAT_FILE_SIZE_EXCEEDED(5005, "文件大小超过限制"),
    CHAT_FILE_TYPE_UNSUPPORTED(5006, "不支持的文件类型"),
    CANNOT_CHAT_WITH_SELF(5007, "不能与自己聊天"),
    CHAT_ROOM_PRODUCT_MISMATCH(5008, "聊天室与商品不匹配"),

    // ==================== 文件错误 6xxx ====================
    FILE_NOT_FOUND(6000, "文件不存在"),
    FILE_UPLOAD_FAILED(6001, "文件上传失败"),
    FILE_SIZE_EXCEEDED(6002, "文件大小超过限制"),
    FILE_TYPE_UNSUPPORTED(6003, "不支持的文件类型"),
    FILE_NAME_INVALID(6004, "文件名不合法"),
    FILE_EMPTY(6005, "文件内容为空"),
    IMAGE_FORMAT_ERROR(6006, "图片格式错误"),
    IMAGE_SIZE_EXCEEDED(6007, "图片大小超过限制"),
    IMAGE_DIMENSION_INVALID(6008, "图片尺寸不符合要求"),
    FILE_DELETE_FAILED(6009, "文件删除失败"),

    // ==================== 地址错误 7xxx ====================
    ADDRESS_NOT_FOUND(7000, "地址不存在"),
    ADDRESS_LIMIT_EXCEEDED(7001, "地址数量已达上限"),
    ADDRESS_NOT_OWNER(7002, "您不是该地址的所有者"),
    ADDRESS_PROVINCE_REQUIRED(7003, "省份不能为空"),
    ADDRESS_CITY_REQUIRED(7004, "城市不能为空"),
    ADDRESS_DETAIL_REQUIRED(7005, "详细地址不能为空"),
    ADDRESS_CONTACT_REQUIRED(7006, "联系人不能为空"),
    ADDRESS_PHONE_REQUIRED(7007, "联系电话不能为空"),

    // ==================== 通知错误 8xxx ====================
    NOTIFICATION_NOT_FOUND(8000, "通知不存在"),
    NOTIFICATION_ALREADY_READ(8001, "通知已读"),
    NOTIFICATION_SEND_FAILED(8002, "通知发送失败"),
    NOTIFICATION_TYPE_INVALID(8003, "通知类型不正确"),

    // ==================== 限流错误 9xxx ====================
    RATE_LIMIT_EXCEEDED(9000, "操作过于频繁,请稍后再试"),
    DAILY_LIMIT_EXCEEDED(9001, "今日操作次数已达上限"),
    CONCURRENT_LIMIT_EXCEEDED(9002, "当前操作人数过多,请稍后再试"),
    IP_BLOCKED(9003, "您的IP已被封禁"),
    ACCOUNT_OPERATION_LIMIT(9004, "账号操作受限");

    /**
     * 错误码
     */
    private final int code;

    /**
     * 错误消息
     */
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
}
