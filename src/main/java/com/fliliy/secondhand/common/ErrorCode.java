package com.fliliy.secondhand.common;

public enum ErrorCode {
    // 系统错误
    SUCCESS(200, "success"),
    SYSTEM_ERROR(500, "系统内部错误"),
    PARAM_ERROR(400, "参数错误"),
    UNAUTHORIZED(401, "未认证"),
    FORBIDDEN(403, "权限不足"),
    NOT_FOUND(404, "资源不存在"),
    TOO_MANY_REQUESTS(429, "请求过于频繁"),
    
    // 认证相关错误 1001-1099
    MOBILE_FORMAT_ERROR(1001, "手机号格式错误"),
    PASSWORD_FORMAT_ERROR(1002, "密码格式错误"),
    SMS_CODE_ERROR(1003, "验证码错误"),
    SMS_CODE_EXPIRED(1004, "验证码已过期"),
    SMS_SEND_TOO_FREQUENT(1005, "验证码发送过于频繁"),
    USER_ALREADY_EXISTS(1006, "用户已存在"),
    USER_NOT_EXISTS(1007, "用户不存在"),
    PASSWORD_INCORRECT(1008, "密码错误"),
    ACCOUNT_LOCKED(1009, "账号已锁定"),
    TOKEN_EXPIRED(1010, "Token已过期"),
    TOKEN_INVALID(1011, "Token无效"),
    OAUTH_LOGIN_FAILED(1012, "第三方登录失败"),
    NEED_BIND_MOBILE(1013, "需要绑定手机号"),
    SMS_CODE_ATTEMPTS_EXCEEDED(1014, "验证码尝试次数超限"),
    LOGIN_ATTEMPTS_EXCEEDED(1015, "登录尝试次数超限"),
    
    // 业务相关错误 2001-2099
    TERMS_NOT_AGREED(2001, "请同意服务条款"),
    PASSWORD_NOT_MATCH(2002, "两次密码输入不一致"),
    OLD_PASSWORD_INCORRECT(2003, "原密码错误"),
    SAME_PASSWORD(2004, "新密码不能与原密码相同");
    
    private final int code;
    private final String message;
    
    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
    
    public int getCode() {
        return code;
    }
    
    public String getMessage() {
        return message;
    }
}