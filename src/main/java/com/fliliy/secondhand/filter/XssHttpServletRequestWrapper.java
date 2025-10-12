package com.fliliy.secondhand.filter;

import org.apache.commons.lang3.StringUtils;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * XSS请求包装器
 * 对请求参数进行XSS过滤处理，支持白名单配置
 */
public class XssHttpServletRequestWrapper extends HttpServletRequestWrapper {

    // 白名单路径：这些路径不进行XSS过滤
    private static final Set<String> WHITELIST_PATHS = new HashSet<>(Arrays.asList(
            "/api/v1/products/upload",  // 商品图片上传
            "/api/v1/chats/upload"      // 聊天文件上传
    ));

    // 允许的安全HTML标签（用于商品描述等场景）
    private static final Set<String> ALLOWED_TAGS = new HashSet<>(Arrays.asList(
            "b", "i", "u", "strong", "em", "br", "p", "span", "div"
    ));

    // 允许的安全HTML属性
    private static final Set<String> ALLOWED_ATTRIBUTES = new HashSet<>(Arrays.asList(
            "class", "style"
    ));

    private final boolean enableWhitelist;

    public XssHttpServletRequestWrapper(HttpServletRequest request) {
        this(request, true);
    }

    public XssHttpServletRequestWrapper(HttpServletRequest request, boolean enableWhitelist) {
        super(request);
        this.enableWhitelist = enableWhitelist;
    }

    @Override
    public String[] getParameterValues(String name) {
        String[] values = super.getParameterValues(name);
        if (values == null) {
            return null;
        }

        int length = values.length;
        String[] escapedValues = new String[length];
        for (int i = 0; i < length; i++) {
            escapedValues[i] = cleanXSS(values[i]);
        }
        return escapedValues;
    }

    @Override
    public String getParameter(String name) {
        String value = super.getParameter(name);
        if (StringUtils.isEmpty(value)) {
            return value;
        }
        return cleanXSS(value);
    }

    @Override
    public String getHeader(String name) {
        String value = super.getHeader(name);
        if (StringUtils.isEmpty(value)) {
            return value;
        }
        return cleanXSS(value);
    }

    /**
     * 清理XSS攻击代码
     *
     * @param value 原始值
     * @return 清理后的值
     */
    private String cleanXSS(String value) {
        if (StringUtils.isEmpty(value)) {
            return value;
        }

        // 检查是否在白名单路径中
        if (enableWhitelist && isInWhitelist()) {
            return cleanXSSWithWhitelist(value);
        }

        // 默认严格过滤
        return cleanXSSStrict(value);
    }

    /**
     * 检查当前请求路径是否在白名单中
     */
    private boolean isInWhitelist() {
        String requestURI = getRequestURI();
        return WHITELIST_PATHS.stream().anyMatch(requestURI::contains);
    }

    /**
     * 带白名单的XSS清理（允许安全的HTML标签）
     */
    private String cleanXSSWithWhitelist(String value) {
        // 移除危险标签和属性
        value = removeDangerousTags(value);
        value = removeDangerousProtocols(value);
        value = removeDangerousEvents(value);

        // 清理不在白名单中的标签
        value = cleanNotAllowedTags(value);

        return value;
    }

    /**
     * 严格的XSS清理（不允许任何HTML标签）
     */
    private String cleanXSSStrict(String value) {
        // 移除脚本标签
        value = value.replaceAll("<script>(.*?)</script>", "");
        value = value.replaceAll("(?i)<script", "");
        value = value.replaceAll("(?i)</script>", "");

        // 移除iframe标签
        value = value.replaceAll("<iframe>(.*?)</iframe>", "");
        value = value.replaceAll("(?i)<iframe", "");
        value = value.replaceAll("(?i)</iframe>", "");

        // 移除样式标签
        value = value.replaceAll("<style>(.*?)</style>", "");
        value = value.replaceAll("(?i)<style", "");
        value = value.replaceAll("(?i)</style>", "");

        // 移除javascript:伪协议
        value = value.replaceAll("(?i)javascript:", "");

        // 移除eval函数
        value = value.replaceAll("(?i)eval\\((.*?)\\)", "");

        // 移除表达式
        value = value.replaceAll("(?i)expression\\((.*?)\\)", "");

        // 移除vbscript
        value = value.replaceAll("(?i)vbscript:", "");

        // 移除data:协议
        value = value.replaceAll("(?i)data:", "");

        // 移除onload等事件
        value = value.replaceAll("(?i)onload(.*?)=", "");
        value = value.replaceAll("(?i)onerror(.*?)=", "");
        value = value.replaceAll("(?i)onclick(.*?)=", "");
        value = value.replaceAll("(?i)onmouseover(.*?)=", "");
        value = value.replaceAll("(?i)onmouseout(.*?)=", "");
        value = value.replaceAll("(?i)onfocus(.*?)=", "");
        value = value.replaceAll("(?i)onblur(.*?)=", "");

        // HTML实体转义
        value = escapeHtml(value);

        return value;
    }

    /**
     * 移除危险标签
     */
    private String removeDangerousTags(String value) {
        // 危险标签列表
        String[] dangerousTags = {"script", "iframe", "object", "embed", "applet", "link", "style", "meta"};

        for (String tag : dangerousTags) {
            value = value.replaceAll("(?i)<" + tag + "\\b[^>]*>", "");
            value = value.replaceAll("(?i)</" + tag + ">", "");
        }

        return value;
    }

    /**
     * 移除危险协议
     */
    private String removeDangerousProtocols(String value) {
        value = value.replaceAll("(?i)javascript:", "");
        value = value.replaceAll("(?i)vbscript:", "");
        value = value.replaceAll("(?i)data:", "");
        value = value.replaceAll("(?i)about:", "");
        return value;
    }

    /**
     * 移除危险事件
     */
    private String removeDangerousEvents(String value) {
        // 所有on开头的事件属性
        value = value.replaceAll("(?i)\\bon\\w+\\s*=", "");
        return value;
    }

    /**
     * 清理不在白名单中的HTML标签
     */
    private String cleanNotAllowedTags(String value) {
        // 使用正则表达式匹配所有HTML标签
        Pattern tagPattern = Pattern.compile("<(/?)(\\w+)([^>]*)>");
        java.util.regex.Matcher matcher = tagPattern.matcher(value);

        StringBuffer result = new StringBuffer();
        while (matcher.find()) {
            String tagName = matcher.group(2).toLowerCase();

            if (ALLOWED_TAGS.contains(tagName)) {
                // 允许的标签，保留但清理属性
                String attributes = matcher.group(3);
                String cleanedAttributes = cleanAttributes(attributes);
                matcher.appendReplacement(result, "<" + matcher.group(1) + tagName + cleanedAttributes + ">");
            } else {
                // 不允许的标签，移除
                matcher.appendReplacement(result, "");
            }
        }
        matcher.appendTail(result);

        return result.toString();
    }

    /**
     * 清理HTML属性，只保留白名单中的属性
     */
    private String cleanAttributes(String attributes) {
        if (StringUtils.isEmpty(attributes)) {
            return "";
        }

        // 简单实现：只保留class和style属性
        Pattern attrPattern = Pattern.compile("(\\w+)\\s*=\\s*[\"']([^\"']*)[\"']");
        java.util.regex.Matcher matcher = attrPattern.matcher(attributes);

        StringBuilder result = new StringBuilder();
        while (matcher.find()) {
            String attrName = matcher.group(1).toLowerCase();
            String attrValue = matcher.group(2);

            if (ALLOWED_ATTRIBUTES.contains(attrName)) {
                // 清理属性值中的危险内容
                attrValue = removeDangerousProtocols(attrValue);
                result.append(" ").append(attrName).append("=\"").append(attrValue).append("\"");
            }
        }

        return result.toString();
    }

    /**
     * HTML实体转义
     */
    private String escapeHtml(String value) {
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;")
                    .replace("/", "&#x2F;");
    }
}
