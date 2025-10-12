package com.fliliy.secondhand.document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 商品Elasticsearch文档
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(indexName = "products")
public class ProductDocument {

    @Id
    private Long id;

    /**
     * 商品标题 - 使用IK分词器
     */
    @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_smart")
    private String title;

    /**
     * 商品描述 - 使用IK分词器
     */
    @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_smart")
    private String description;

    /**
     * 价格
     */
    @Field(type = FieldType.Double)
    private BigDecimal price;

    /**
     * 分类ID
     */
    @Field(type = FieldType.Integer)
    private Integer categoryId;

    /**
     * 分类名称
     */
    @Field(type = FieldType.Keyword)
    private String categoryName;

    /**
     * 省份
     */
    @Field(type = FieldType.Keyword)
    private String province;

    /**
     * 城市
     */
    @Field(type = FieldType.Keyword)
    private String city;

    /**
     * 商品状态
     */
    @Field(type = FieldType.Keyword)
    private String status;

    /**
     * 卖家ID
     */
    @Field(type = FieldType.Long)
    private Long sellerId;

    /**
     * 卖家昵称
     */
    @Field(type = FieldType.Keyword)
    private String sellerNickname;

    /**
     * 卖家头像
     */
    @Field(type = FieldType.Keyword, index = false)
    private String sellerAvatar;

    /**
     * 主图URL
     */
    @Field(type = FieldType.Keyword, index = false)
    private String mainImage;

    /**
     * 浏览次数
     */
    @Field(type = FieldType.Integer)
    private Integer viewCount;

    /**
     * 收藏次数
     */
    @Field(type = FieldType.Integer)
    private Integer favoriteCount;

    /**
     * 发布时间
     */
    @Field(type = FieldType.Date, format = {}, pattern = "uuuu-MM-dd'T'HH:mm:ss.SSS'Z'||uuuu-MM-dd'T'HH:mm:ss||uuuu-MM-dd")
    private LocalDateTime publishedAt;

    /**
     * 创建时间
     */
    @Field(type = FieldType.Date, format = {}, pattern = "uuuu-MM-dd'T'HH:mm:ss.SSS'Z'||uuuu-MM-dd'T'HH:mm:ss||uuuu-MM-dd")
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @Field(type = FieldType.Date, format = {}, pattern = "uuuu-MM-dd'T'HH:mm:ss.SSS'Z'||uuuu-MM-dd'T'HH:mm:ss||uuuu-MM-dd")
    private LocalDateTime updatedAt;
}
