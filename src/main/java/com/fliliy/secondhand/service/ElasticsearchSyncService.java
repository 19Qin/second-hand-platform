package com.fliliy.secondhand.service;

import com.fliliy.secondhand.document.ProductDocument;
import com.fliliy.secondhand.entity.Category;
import com.fliliy.secondhand.entity.Product;
import com.fliliy.secondhand.entity.User;
import com.fliliy.secondhand.repository.CategoryRepository;
import com.fliliy.secondhand.repository.ProductRepository;
import com.fliliy.secondhand.repository.ProductSearchRepository;
import com.fliliy.secondhand.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Elasticsearch同步服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ElasticsearchSyncService {

    private final ProductRepository productRepository;
    private final ProductSearchRepository productSearchRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final com.fliliy.secondhand.repository.ProductImageRepository productImageRepository;
    private final ElasticsearchIndexService elasticsearchIndexService;

    /**
     * 同步单个商品到ES
     */
    @Transactional(readOnly = true)
    public void syncProduct(Long productId) {
        log.info("开始同步商品到ES: {}", productId);

        Optional<Product> productOpt = productRepository.findByIdAndNotDeleted(productId);
        if (!productOpt.isPresent()) {
            log.warn("商品不存在或已删除: {}", productId);
            return;
        }

        Product product = productOpt.get();

        // 只同步ACTIVE状态的商品
        if (product.getStatus() != Product.ProductStatus.ACTIVE) {
            log.info("商品状态不是ACTIVE,不同步: {} - {}", productId, product.getStatus());
            deleteProductFromEs(productId);
            return;
        }

        try {
            ProductDocument document = convertToDocument(product);

            // 验证必填字段
            if (document.getId() == null || document.getTitle() == null) {
                log.error("商品文档数据不完整，跳过同步 - 商品ID: {}", productId);
                return;
            }

            // 使用 RestHighLevelClient 直接索引，避免响应解析问题
            boolean success = elasticsearchIndexService.indexProduct(document);
            if (success) {
                log.info("商品同步成功: {}", productId);
            } else {
                log.warn("商品同步失败: {}", productId);
            }
        } catch (Exception e) {
            log.error("同步商品到ES失败 - 商品ID: {}, 错误类型: {}, 错误信息: {}",
                productId, e.getClass().getSimpleName(), e.getMessage(), e);
            // 不抛出异常，避免影响主流程
        }
    }

    /**
     * 全量同步所有ACTIVE状态商品
     */
    @Transactional(readOnly = true)
    public void syncAllProducts() {
        log.info("开始全量同步商品到ES");
        long startTime = System.currentTimeMillis();

        List<Product> activeProducts = productRepository.findByStatus(
            Product.ProductStatus.ACTIVE,
            org.springframework.data.domain.Pageable.unpaged()
        ).getContent();

        log.info("找到 {} 个ACTIVE商品", activeProducts.size());

        List<ProductDocument> documents = activeProducts.stream()
            .map(this::convertToDocument)
            .collect(Collectors.toList());

        productSearchRepository.saveAll(documents);

        long endTime = System.currentTimeMillis();
        log.info("全量同步完成,共同步 {} 个商品,耗时 {} ms", documents.size(), (endTime - startTime));
    }

    /**
     * 从ES删除商品
     */
    public void deleteProductFromEs(Long productId) {
        log.info("从ES删除商品: {}", productId);
        // 使用 RestHighLevelClient 直接删除，避免响应解析问题
        boolean success = elasticsearchIndexService.deleteProduct(productId);
        if (success) {
            log.info("商品已从ES删除: {}", productId);
        } else {
            log.warn("商品删除失败: {}", productId);
        }
    }

    /**
     * 清空ES索引
     */
    public void clearEsIndex() {
        log.info("开始清空ES索引");
        productSearchRepository.deleteAll();
        log.info("ES索引清空完成");
    }

    /**
     * 重建索引(清空+全量同步)
     */
    public void rebuildIndex() {
        log.info("开始重建ES索引");
        clearEsIndex();
        syncAllProducts();
        log.info("ES索引重建完成");
    }

    /**
     * 转换Product到ProductDocument
     */
    private ProductDocument convertToDocument(Product product) {
        ProductDocument document = new ProductDocument();
        document.setId(product.getId());
        document.setTitle(product.getTitle());
        document.setDescription(product.getDescription());
        document.setPrice(product.getPrice());
        document.setCategoryId(product.getCategoryId());
        document.setProvince(product.getProvince());
        document.setCity(product.getCity());
        document.setStatus(product.getStatus().name());
        document.setSellerId(product.getSellerId());

        // 获取主图URL
        try {
            Optional<String> mainImageUrl = productImageRepository.findMainImageUrl(product.getId());
            mainImageUrl.ifPresent(document::setMainImage);
        } catch (Exception e) {
            log.warn("获取商品主图失败: {}", product.getId(), e);
        }

        document.setViewCount(product.getViewCount());
        document.setFavoriteCount(product.getFavoriteCount());
        document.setPublishedAt(product.getPublishedAt());
        document.setCreatedAt(product.getCreatedAt());
        document.setUpdatedAt(product.getUpdatedAt());

        // 获取分类名称
        try {
            Optional<Category> categoryOpt = categoryRepository.findById(product.getCategoryId());
            categoryOpt.ifPresent(category -> document.setCategoryName(category.getName()));
        } catch (Exception e) {
            log.warn("获取分类信息失败: {}", product.getCategoryId(), e);
        }

        // 获取卖家信息
        try {
            Optional<User> userOpt = userRepository.findById(product.getSellerId());
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                document.setSellerNickname(user.getUsername());
                document.setSellerAvatar(user.getAvatar());
            }
        } catch (Exception e) {
            log.warn("获取卖家信息失败: {}", product.getSellerId(), e);
        }

        return document;
    }
}
