package com.fliliy.secondhand.exception;

import com.fliliy.secondhand.common.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

import javax.servlet.http.HttpServletRequest;
import javax.validation.ConstraintViolation;
import javax.validation.ConstraintViolationException;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 全局异常处理器
 * 统一处理所有异常,返回标准的错误响应
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    /**
     * 处理业务异常
     * 这是最常用的异常类型,用于封装业务逻辑中的错误
     */
    @ExceptionHandler(BusinessException.class)
    public ApiResponse<Object> handleBusinessException(BusinessException e, HttpServletRequest request) {
        log.warn("Business exception at {}: [{}] {}",
            request.getRequestURI(), e.getCode(), e.getMessage());
        return ApiResponse.error(e.getCode(), e.getMessage());
    }

    /**
     * 处理参数校验异常 - @RequestBody参数校验失败
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleValidationException(MethodArgumentNotValidException e, HttpServletRequest request) {
        // 收集所有字段错误
        String errors = e.getBindingResult().getFieldErrors().stream()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .collect(Collectors.joining("; "));

        log.warn("Validation failed at {}: {}", request.getRequestURI(), errors);

        // 只返回第一个错误给前端
        FieldError fieldError = e.getBindingResult().getFieldError();
        String message = fieldError != null ? fieldError.getDefaultMessage() : "参数校验失败";
        return ApiResponse.error(ErrorCode.PARAM_ERROR.getCode(), message);
    }

    /**
     * 处理绑定异常 - @ModelAttribute参数绑定失败
     */
    @ExceptionHandler(BindException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleBindException(BindException e, HttpServletRequest request) {
        FieldError fieldError = e.getFieldError();
        String message = fieldError != null ? fieldError.getDefaultMessage() : "参数绑定失败";
        log.warn("Bind exception at {}: {}", request.getRequestURI(), message);
        return ApiResponse.error(ErrorCode.PARAM_ERROR.getCode(), message);
    }

    /**
     * 处理约束违反异常 - @Validated路径参数校验失败
     */
    @ExceptionHandler(ConstraintViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleConstraintViolationException(ConstraintViolationException e, HttpServletRequest request) {
        Set<ConstraintViolation<?>> violations = e.getConstraintViolations();
        String message = "参数校验失败";
        if (!violations.isEmpty()) {
            message = violations.iterator().next().getMessage();
        }
        log.warn("Constraint violation at {}: {}", request.getRequestURI(), message);
        return ApiResponse.error(ErrorCode.PARAM_ERROR.getCode(), message);
    }

    /**
     * 处理缺少请求参数异常
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleMissingParameter(MissingServletRequestParameterException e, HttpServletRequest request) {
        String message = String.format("缺少必需参数: %s", e.getParameterName());
        log.warn("Missing parameter at {}: {}", request.getRequestURI(), e.getParameterName());
        return ApiResponse.error(ErrorCode.PARAM_MISSING.getCode(), message);
    }

    /**
     * 处理参数类型不匹配异常
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleTypeMismatch(MethodArgumentTypeMismatchException e, HttpServletRequest request) {
        String message = String.format("参数类型错误: %s", e.getName());
        log.warn("Type mismatch at {}: {} expected type {}",
            request.getRequestURI(), e.getName(), e.getRequiredType());
        return ApiResponse.error(ErrorCode.PARAM_TYPE_ERROR.getCode(), message);
    }

    /**
     * 处理404异常
     */
    @ExceptionHandler(NoHandlerFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiResponse<Object> handleNotFound(NoHandlerFoundException e, HttpServletRequest request) {
        log.warn("Not found: {} {}", e.getHttpMethod(), e.getRequestURL());
        return ApiResponse.error(404, "请求的资源不存在");
    }

    /**
     * 处理IllegalArgumentException
     * 通常用于方法参数校验
     */
    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleIllegalArgument(IllegalArgumentException e, HttpServletRequest request) {
        log.warn("Illegal argument at {}: {}", request.getRequestURI(), e.getMessage());
        return ApiResponse.error(ErrorCode.PARAM_ERROR.getCode(), e.getMessage());
    }

    /**
     * 处理IllegalStateException
     * 通常用于状态不正确的场景
     */
    @ExceptionHandler(IllegalStateException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleIllegalState(IllegalStateException e, HttpServletRequest request) {
        log.warn("Illegal state at {}: {}", request.getRequestURI(), e.getMessage());
        return ApiResponse.error(ErrorCode.SYSTEM_ERROR.getCode(), e.getMessage());
    }

    /**
     * 处理NullPointerException
     * 这通常是代码bug,需要重点关注
     */
    @ExceptionHandler(NullPointerException.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiResponse<Object> handleNullPointer(NullPointerException e, HttpServletRequest request) {
        log.error("Null pointer exception at {}: ", request.getRequestURI(), e);
        return ApiResponse.error(ErrorCode.SYSTEM_ERROR.getCode(), "系统内部错误");
    }

    /**
     * 处理运行时异常
     * 除了上面明确处理的异常外的其他运行时异常
     */
    @ExceptionHandler(RuntimeException.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiResponse<Object> handleRuntimeException(RuntimeException e, HttpServletRequest request) {
        log.error("Runtime exception at {}: ", request.getRequestURI(), e);
        // 生产环境不应该暴露详细错误信息
        return ApiResponse.error(ErrorCode.SYSTEM_ERROR.getCode(), "系统内部错误");
    }

    /**
     * 处理其他所有未捕获的异常
     * 这是最后的兜底异常处理
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiResponse<Object> handleException(Exception e, HttpServletRequest request) {
        log.error("Unexpected exception at {}: ", request.getRequestURI(), e);
        return ApiResponse.error(ErrorCode.SYSTEM_ERROR.getCode(), "系统内部错误");
    }
}