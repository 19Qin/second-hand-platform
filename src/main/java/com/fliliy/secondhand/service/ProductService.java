package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.request.ProductQueryRequest;
import com.fliliy.secondhand.dto.request.PublishProductRequest;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.dto.response.ProductDetailResponse;
import com.fliliy.secondhand.dto.response.ProductSummaryResponse;
import com.fliliy.secondhand.entity.*;
import com.fliliy.secondhand.repository.*;
import com.fliliy.secondhand.util.IdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.persistence.criteria.Predicate;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProductService {
    
    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductImageRepository productImageRepository;
    private final ProductTagRepository productTagRepository;
    private final ProductFavoriteRepository productFavoriteRepository;
    private final UserRepository userRepository;
    private final CategoryService categoryService;
    
    /**
     * 发布商品
     */
    @Transactional
    public Long publishProduct(PublishProductRequest request, Long sellerId) {
        // 1. 验证分类是否存在
        if (!categoryService.isCategoryValid(request.getCategoryId())) {
            throw new RuntimeException("商品分类不存在或已禁用");
        }
        
        // 2. 验证图片
        if (request.getImages() == null || request.getImages().isEmpty()) {
            throw new RuntimeException("至少需要上传一张商品图片");
        }
        
        if (request.getImages().size() > 20) {
            throw new RuntimeException("商品图片最多20张");
        }
        
        // 3. 创建商品
        Product product = new Product();
        product.setId(IdGenerator.generateProductId());
        product.setSellerId(sellerId);
        product.setCategoryId(request.getCategoryId());
        product.setTitle(request.getTitle());
        product.setDescription(request.getDescription());
        product.setPrice(request.getPrice());
        product.setOriginalPrice(request.getOriginalPrice());
        product.setProductCondition(Product.ConditionType.valueOf(request.getCondition()));
        
        // 设置使用信息
        if (request.getUsageInfo() != null) {
            product.setUsageType(Product.UsageType.valueOf(request.getUsageInfo().getType()));
            product.setUsageValue(request.getUsageInfo().getValue());
            if ("TIME".equals(request.getUsageInfo().getType()) && request.getUsageInfo().getUnit() != null) {
                product.setUsageUnit(Product.UsageUnit.valueOf(request.getUsageInfo().getUnit()));
            }
        }
        
        // 设置保修信息
        if (request.getWarranty() != null) {
            product.setHasWarranty(request.getWarranty().getHasWarranty());
            product.setWarrantyType(Product.WarrantyType.valueOf(request.getWarranty().getWarrantyType()));
            product.setWarrantyMonths(request.getWarranty().getRemainingMonths());
            product.setWarrantyDescription(request.getWarranty().getDescription());
        }
        
        // 设置位置信息
        if (request.getLocation() != null) {
            product.setProvince(request.getLocation().getProvince());
            product.setCity(request.getLocation().getCity());
            product.setDistrict(request.getLocation().getDistrict());
            product.setDetailAddress(request.getLocation().getDetailAddress());
            product.setLongitude(request.getLocation().getLongitude());
            product.setLatitude(request.getLocation().getLatitude());
        }
        
        product.setPublishedAt(LocalDateTime.now());
        
        // 保存商品
        Product savedProduct = productRepository.save(product);
        
        // 4. 保存商品图片
        saveProductImages(savedProduct.getId(), request.getImages());
        
        // 5. 保存商品标签
        if (request.getTags() != null && !request.getTags().isEmpty()) {
            saveProductTags(savedProduct.getId(), request.getTags());
        }
        
        // 6. 更新分类商品数量
        categoryService.updateCategoryProductCount(request.getCategoryId());
        
        log.info("Product published successfully: id={}, title={}, seller={}", 
                savedProduct.getId(), savedProduct.getTitle(), sellerId);
        
        return savedProduct.getId();
    }
    
    /**
     * 获取商品列表（主页/搜索/筛选）
     */
    public PagedResponse<ProductSummaryResponse> getProducts(ProductQueryRequest request, Long currentUserId) {
        // 构建查询规格
        Specification<Product> spec = buildProductSpecification(request);
        
        // 构建排序
        Sort sort = buildSort(request.getSort());
        Pageable pageable = PageRequest.of(request.getPage() - 1, request.getSize(), sort);
        
        // 执行查询
        Page<Product> productsPage = productRepository.findAll(spec, pageable);
        
        // 转换为响应对象
        List<ProductSummaryResponse> summaries = convertToSummaryResponses(
                productsPage.getContent(), currentUserId);
        
        // 构建筛选条件汇总
        Object filters = buildFiltersInfo(request);
        
        return PagedResponse.of(summaries, productsPage, filters);
    }
    
    /**
     * 获取商品详情
     */
    @Transactional
    public ProductDetailResponse getProductDetail(Long productId, Long currentUserId) {
        // 查找商品
        Product product = productRepository.findByIdAndNotDeleted(productId)
                .orElseThrow(() -> new RuntimeException("商品不存在"));
        
        // 增加浏览次数（异步处理避免影响响应速度）
        productRepository.incrementViewCount(productId);
        
        // 获取相关数据
        List<ProductImage> images = productImageRepository.findByProductIdOrderBySortOrder(productId);
        List<String> tags = productTagRepository.findTagNamesByProductId(productId);
        
        // 获取卖家信息
        User seller = userRepository.findById(product.getSellerId())
                .orElseThrow(() -> new RuntimeException("卖家信息不存在"));
        
        // 获取分类信息
        Category category = categoryRepository.findById(product.getCategoryId())
                .orElse(null);
        
        // 检查是否收藏
        boolean isFavorited = false;
        if (currentUserId != null) {
            isFavorited = productFavoriteRepository.existsByUserIdAndProductId(currentUserId, productId);
        }
        
        // 获取相关推荐商品
        List<Product> relatedProducts = productRepository.findRelatedProducts(
                product.getCategoryId(), productId, PageRequest.of(0, 4));
        
        // 构建响应
        return convertToDetailResponse(product, images, tags, seller, category, 
                isFavorited, currentUserId, relatedProducts);
    }
    
    /**
     * 收藏/取消收藏商品
     */
    @Transactional
    public Map<String, Object> toggleFavorite(Long productId, Long userId) {
        // 检查商品是否存在
        Product product = productRepository.findByIdAndNotDeleted(productId)
                .orElseThrow(() -> new RuntimeException("商品不存在"));
        
        // 检查是否已收藏
        Optional<ProductFavorite> existingFavorite = 
                productFavoriteRepository.findByUserIdAndProductId(userId, productId);
        
        boolean isFavorited;
        if (existingFavorite.isPresent()) {
            // 取消收藏
            productFavoriteRepository.delete(existingFavorite.get());
            productRepository.updateFavoriteCount(productId, -1);
            isFavorited = false;
            log.info("Product unfavorited: productId={}, userId={}", productId, userId);
        } else {
            // 添加收藏
            ProductFavorite favorite = new ProductFavorite(userId, productId);
            productFavoriteRepository.save(favorite);
            productRepository.updateFavoriteCount(productId, 1);
            isFavorited = true;
            log.info("Product favorited: productId={}, userId={}", productId, userId);
        }
        
        // 获取最新收藏数
        Long favoriteCount = productFavoriteRepository.countByProductId(productId);
        
        Map<String, Object> result = new HashMap<>();
        result.put("isFavorited", isFavorited);
        result.put("favoriteCount", favoriteCount);
        
        return result;
    }
    
    /**
     * 编辑商品
     */
    @Transactional
    public void updateProduct(Long productId, PublishProductRequest request, Long sellerId) {
        // 查找商品并验证权限
        Product product = productRepository.findByIdAndNotDeleted(productId)
                .orElseThrow(() -> new RuntimeException("商品不存在"));
        
        if (!product.getSellerId().equals(sellerId)) {
            throw new RuntimeException("无权限编辑此商品");
        }
        
        // 验证分类
        if (!categoryService.isCategoryValid(request.getCategoryId())) {
            throw new RuntimeException("商品分类不存在或已禁用");
        }
        
        // 更新商品信息
        product.setTitle(request.getTitle());
        product.setDescription(request.getDescription());
        product.setPrice(request.getPrice());
        product.setOriginalPrice(request.getOriginalPrice());
        product.setProductCondition(Product.ConditionType.valueOf(request.getCondition()));
        
        // 更新其他信息...（类似发布商品的逻辑）
        
        productRepository.save(product);
        
        // 重新保存图片和标签
        productImageRepository.deleteByProductId(productId);
        productTagRepository.deleteByProductId(productId);
        
        saveProductImages(productId, request.getImages());
        if (request.getTags() != null && !request.getTags().isEmpty()) {
            saveProductTags(productId, request.getTags());
        }
        
        log.info("Product updated: id={}, seller={}", productId, sellerId);
    }
    
    /**
     * 删除商品（下架）
     */
    @Transactional
    public void deleteProduct(Long productId, Long sellerId) {
        // 查找商品并验证权限
        Product product = productRepository.findByIdAndNotDeleted(productId)
                .orElseThrow(() -> new RuntimeException("商品不存在"));
        
        if (!product.getSellerId().equals(sellerId)) {
            throw new RuntimeException("无权限删除此商品");
        }
        
        // 软删除商品
        productRepository.softDeleteById(productId);
        
        // 更新分类商品数量
        categoryService.updateCategoryProductCount(product.getCategoryId());
        
        log.info("Product deleted: id={}, seller={}", productId, sellerId);
    }
    
    /**
     * 根据ID获取商品详情
     */
    @Transactional(readOnly = true)
    public Product getProductById(Long productId) {
        return productRepository.findByIdAndNotDeleted(productId)
                .orElseThrow(() -> new RuntimeException("商品不存在"));
    }
    
    // 私有方法
    
    private void saveProductImages(Long productId, List<String> imageUrls) {
        for (int i = 0; i < imageUrls.size(); i++) {
            ProductImage image = new ProductImage();
            image.setProductId(productId);
            image.setImageUrl(imageUrls.get(i));
            image.setSortOrder(i); // 第一张为主图（sortOrder=0）
            productImageRepository.save(image);
        }
    }
    
    private void saveProductTags(Long productId, List<String> tags) {
        for (String tagName : tags) {
            if (StringUtils.hasText(tagName)) {
                ProductTag tag = new ProductTag(productId, tagName.trim());
                productTagRepository.save(tag);
            }
        }
    }
    
    private Specification<Product> buildProductSpecification(ProductQueryRequest request) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();
            
            // 基本条件：非删除状态
            predicates.add(criteriaBuilder.isNull(root.get("deletedAt")));
            
            // 商品状态筛选
            if (!"ALL".equals(request.getStatus())) {
                Product.ProductStatus status = Product.ProductStatus.valueOf(request.getStatus());
                predicates.add(criteriaBuilder.equal(root.get("status"), status));
            }
            
            // 分类筛选（包含子分类）
            if (request.getCategoryId() != null) {
                List<Integer> categoryIds = categoryService.getCategoryIdsIncludeChildren(request.getCategoryId());
                predicates.add(root.get("categoryId").in(categoryIds));
            }
            
            // 关键词搜索
            if (StringUtils.hasText(request.getKeyword())) {
                String keyword = "%" + request.getKeyword().trim() + "%";
                Predicate titleMatch = criteriaBuilder.like(root.get("title"), keyword);
                Predicate descMatch = criteriaBuilder.like(root.get("description"), keyword);
                predicates.add(criteriaBuilder.or(titleMatch, descMatch));
            }
            
            // 价格区间
            if (request.getMinPrice() != null) {
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("price"), request.getMinPrice()));
            }
            if (request.getMaxPrice() != null) {
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("price"), request.getMaxPrice()));
            }
            
            // 商品状况
            if (StringUtils.hasText(request.getCondition())) {
                Product.ConditionType condition = Product.ConditionType.valueOf(request.getCondition());
                predicates.add(criteriaBuilder.equal(root.get("productCondition"), condition));
            }
            
            // 保修筛选
            if (request.getHasWarranty() != null) {
                predicates.add(criteriaBuilder.equal(root.get("hasWarranty"), request.getHasWarranty()));
            }
            
            // 地区筛选
            if (StringUtils.hasText(request.getProvince())) {
                predicates.add(criteriaBuilder.equal(root.get("province"), request.getProvince()));
            }
            if (StringUtils.hasText(request.getCity())) {
                predicates.add(criteriaBuilder.equal(root.get("city"), request.getCity()));
            }
            if (StringUtils.hasText(request.getDistrict())) {
                predicates.add(criteriaBuilder.equal(root.get("district"), request.getDistrict()));
            }
            
            // 卖家筛选
            if (request.getSellerId() != null) {
                predicates.add(criteriaBuilder.equal(root.get("sellerId"), request.getSellerId()));
            }
            
            // 筛选条件处理
            if (StringUtils.hasText(request.getFilter())) {
                switch (request.getFilter()) {
                    case "all":
                        // all：显示所有商品，无需额外筛选条件
                        break;
                    case "discount":
                        // discount：有打折的商品（有原价且现价低于原价）
                        predicates.add(criteriaBuilder.isNotNull(root.get("originalPrice")));
                        predicates.add(criteriaBuilder.lessThan(root.get("price"), root.get("originalPrice")));
                        break;
                    case "brand":
                        // brand：品牌商品（基于商品标题或描述包含品牌关键词）
                        Predicate brandInTitle = criteriaBuilder.or(
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%apple%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%samsung%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%sony%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%nike%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%iphone%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%ps5%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%playstation%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%品牌%")
                        );
                        predicates.add(brandInTitle);
                        break;
                    case "popular":
                        // popular：热门商品（浏览量和收藏数较高的商品）
                        predicates.add(criteriaBuilder.or(
                            criteriaBuilder.greaterThan(root.get("viewCount"), 50),
                            criteriaBuilder.greaterThan(root.get("favoriteCount"), 5)
                        ));
                        break;
                    case "accessories":
                        // accessories：电子配件商品（基于商品标题包含配件关键词）
                        Predicate accessoriesInTitle = criteriaBuilder.or(
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%耳机%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%充电器%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%数据线%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%保护壳%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%手机壳%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%移动电源%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%充电宝%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%支架%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%adapter%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%cable%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%case%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%charger%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%headset%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%earphone%"),
                            criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%配件%")
                        );
                        predicates.add(accessoriesInTitle);
                        break;
                    default:
                        // 其他值默认显示所有商品
                        break;
                }
            }
            
            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
    
    private Sort buildSort(String sortStr) {
        if (!StringUtils.hasText(sortStr)) {
            return Sort.by(Sort.Direction.DESC, "publishedAt");
        }
        
        switch (sortStr) {
            case "time_asc":
                return Sort.by(Sort.Direction.ASC, "publishedAt");
            case "price_asc":
                return Sort.by(Sort.Direction.ASC, "price");
            case "price_desc":
                return Sort.by(Sort.Direction.DESC, "price");
            case "view_desc":
                return Sort.by(Sort.Direction.DESC, "viewCount");
            case "favorite_desc":
                return Sort.by(Sort.Direction.DESC, "favoriteCount");
            case "time_desc":
            default:
                return Sort.by(Sort.Direction.DESC, "publishedAt");
        }
    }
    
    private List<ProductSummaryResponse> convertToSummaryResponses(List<Product> products, Long currentUserId) {
        if (products.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 批量获取相关数据
        List<Long> productIds = products.stream().map(Product::getId).collect(Collectors.toList());
        List<Long> sellerIds = products.stream().map(Product::getSellerId).distinct().collect(Collectors.toList());
        
        // 获取主图
        Map<Long, String> mainImages = getMainImages(productIds);
        
        // 获取卖家信息
        Map<Long, User> sellers = getSellers(sellerIds);
        
        // 获取标签
        Map<Long, List<String>> productTags = getProductTags(productIds);
        
        // 获取收藏状态
        Set<Long> favoritedProductIds = getCurrentUserFavorites(currentUserId, productIds);
        
        return products.stream()
                .map(product -> convertToSummaryResponse(product, mainImages, sellers, 
                        productTags, favoritedProductIds, currentUserId))
                .collect(Collectors.toList());
    }
    
    private ProductSummaryResponse convertToSummaryResponse(Product product, 
                                                          Map<Long, String> mainImages,
                                                          Map<Long, User> sellers,
                                                          Map<Long, List<String>> productTags,
                                                          Set<Long> favoritedProductIds,
                                                          Long currentUserId) {
        ProductSummaryResponse response = new ProductSummaryResponse();
        response.setId(product.getId().toString());
        response.setTitle(product.getTitle());
        response.setPrice(product.getPrice());
        response.setOriginalPrice(product.getOriginalPrice());
        response.setMainImage(mainImages.get(product.getId()));
        response.setCondition(product.getProductCondition().name());
        response.setConditionText(product.getProductCondition().getDescription());
        response.setPublishTime(product.getPublishedAt());
        response.setHasWarranty(product.getHasWarranty());
        
        // 商品状态信息 - 商家管理必需字段
        response.setStatus(product.getStatus().name());
        response.setStatusText(product.getStatus().getDescription());
        response.setSoldAt(product.getSoldAt());
        
        // 构建位置信息
        if (product.getProvince() != null && product.getCity() != null) {
            String location = product.getProvince() + product.getCity();
            if (product.getDistrict() != null) {
                location += product.getDistrict();
            }
            response.setLocation(location);
        }
        
        // 计算折扣信息
        if (product.getOriginalPrice() != null && product.getPrice().compareTo(product.getOriginalPrice()) < 0) {
            BigDecimal discount = product.getPrice().divide(product.getOriginalPrice(), 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(10));
            response.setDiscount(discount.setScale(0, RoundingMode.HALF_UP) + "折");
        }
        
        // 保修信息
        if (product.getHasWarranty() && product.getWarrantyMonths() != null && product.getWarrantyMonths() > 0) {
            response.setWarrantyText("保修" + product.getWarrantyMonths() + "个月");
        }
        
        // 卖家信息
        User seller = sellers.get(product.getSellerId());
        if (seller != null) {
            ProductSummaryResponse.SellerInfo sellerInfo = new ProductSummaryResponse.SellerInfo();
            sellerInfo.setId(seller.getId().toString());
            sellerInfo.setUsername(seller.getUsername());
            sellerInfo.setAvatar(seller.getAvatar());
            sellerInfo.setVerified(seller.getVerified());
            // TODO: 设置评分信息
            response.setSeller(sellerInfo);
        }
        
        // 统计信息 - 确保默认值
        ProductSummaryResponse.StatsInfo stats = new ProductSummaryResponse.StatsInfo();
        stats.setViewCount(product.getViewCount() != null ? product.getViewCount() : 0);
        stats.setFavoriteCount(product.getFavoriteCount() != null ? product.getFavoriteCount() : 0);
        stats.setChatCount(product.getChatCount() != null ? product.getChatCount() : 0);
        stats.setIsOwn(currentUserId != null && currentUserId.equals(product.getSellerId()));
        stats.setIsFavorited(favoritedProductIds.contains(product.getId()));
        response.setStats(stats);
        
        // 标签
        response.setTags(productTags.get(product.getId()));
        
        return response;
    }
    
    private ProductDetailResponse convertToDetailResponse(Product product, 
                                                        List<ProductImage> images, 
                                                        List<String> tags, 
                                                        User seller, 
                                                        Category category,
                                                        boolean isFavorited, 
                                                        Long currentUserId,
                                                        List<Product> relatedProducts) {
        ProductDetailResponse response = new ProductDetailResponse();
        
        // 基本信息
        response.setId(product.getId().toString());
        response.setTitle(product.getTitle());
        response.setDescription(product.getDescription());
        response.setPrice(product.getPrice());
        response.setOriginalPrice(product.getOriginalPrice());
        
        // 分类信息
        if (category != null) {
            response.setCategoryId(category.getId());
            response.setCategoryName(category.getName());
            response.setCategoryPath(categoryService.getCategoryPath(category.getId()));
        }
        
        // 图片列表
        response.setImages(images.stream().map(ProductImage::getImageUrl).collect(Collectors.toList()));
        
        // 商品状况
        response.setCondition(product.getProductCondition().name());
        response.setConditionText(product.getProductCondition().getDescription());
        
        // 使用信息
        if (product.getUsageType() != null) {
            ProductDetailResponse.UsageInfo usageInfo = new ProductDetailResponse.UsageInfo();
            usageInfo.setType(product.getUsageType().name());
            usageInfo.setValue(product.getUsageValue());
            if (product.getUsageUnit() != null) {
                usageInfo.setUnit(product.getUsageUnit().name());
            }
            // 构建显示文本
            if (product.getUsageType() == Product.UsageType.TIME && product.getUsageValue() != null) {
                String unit = product.getUsageUnit() == Product.UsageUnit.MONTH ? "个月" : "年";
                usageInfo.setDisplayText("使用" + product.getUsageValue() + unit);
            }
            response.setUsageInfo(usageInfo);
        }
        
        // 保修信息
        ProductDetailResponse.WarrantyInfo warrantyInfo = new ProductDetailResponse.WarrantyInfo();
        warrantyInfo.setHasWarranty(product.getHasWarranty());
        warrantyInfo.setWarrantyType(product.getWarrantyType().name());
        warrantyInfo.setRemainingMonths(product.getWarrantyMonths());
        warrantyInfo.setDescription(product.getWarrantyDescription());
        if (product.getHasWarranty() && product.getWarrantyMonths() != null && product.getWarrantyMonths() > 0) {
            warrantyInfo.setDisplayText(product.getWarrantyType().getDescription() + 
                    "，剩余" + product.getWarrantyMonths() + "个月");
        }
        response.setWarranty(warrantyInfo);
        
        // 位置信息
        ProductDetailResponse.LocationInfo locationInfo = new ProductDetailResponse.LocationInfo();
        locationInfo.setProvince(product.getProvince());
        locationInfo.setCity(product.getCity());
        locationInfo.setDistrict(product.getDistrict());
        locationInfo.setDetailAddress(product.getDetailAddress());
        if (product.getProvince() != null) {
            String displayLocation = product.getProvince() + product.getCity();
            if (product.getDistrict() != null) {
                displayLocation += product.getDistrict();
            }
            if (product.getDetailAddress() != null) {
                displayLocation += product.getDetailAddress();
            }
            locationInfo.setDisplayText(displayLocation);
        }
        response.setLocation(locationInfo);
        
        // 卖家信息
        ProductDetailResponse.SellerInfo sellerInfo = new ProductDetailResponse.SellerInfo();
        sellerInfo.setId(seller.getId().toString());
        sellerInfo.setUsername(seller.getUsername());
        sellerInfo.setAvatar(seller.getAvatar());
        sellerInfo.setVerified(seller.getVerified());
        
        // 计算注册天数
        if (seller.getCreatedAt() != null) {
            long days = ChronoUnit.DAYS.between(seller.getCreatedAt(), LocalDateTime.now());
            sellerInfo.setRegisteredDays((int) days);
        }
        
        // TODO: 统计卖家的其他信息（发布商品数、售出数、评分等）
        response.setSeller(sellerInfo);
        
        // 统计信息
        ProductDetailResponse.StatsInfo stats = new ProductDetailResponse.StatsInfo();
        stats.setViewCount(product.getViewCount());
        stats.setFavoriteCount(product.getFavoriteCount());
        stats.setChatCount(product.getChatCount());
        stats.setIsOwn(currentUserId != null && currentUserId.equals(product.getSellerId()));
        stats.setIsFavorited(isFavorited);
        response.setStats(stats);
        
        // 其他信息
        response.setPublishTime(product.getPublishedAt());
        response.setUpdatedTime(product.getUpdatedAt());
        response.setStatus(product.getStatus().name());
        response.setTags(tags);
        
        // 相关商品
        if (relatedProducts != null && !relatedProducts.isEmpty()) {
            List<ProductDetailResponse.RelatedProduct> related = relatedProducts.stream()
                    .map(p -> {
                        ProductDetailResponse.RelatedProduct rp = new ProductDetailResponse.RelatedProduct();
                        rp.setId(p.getId().toString());
                        rp.setTitle(p.getTitle());
                        rp.setPrice(p.getPrice());
                        // 获取主图
                        productImageRepository.findMainImageUrl(p.getId())
                                .ifPresent(rp::setMainImage);
                        return rp;
                    })
                    .collect(Collectors.toList());
            response.setRelatedProducts(related);
        }
        
        return response;
    }
    
    // 辅助方法
    private Map<Long, String> getMainImages(List<Long> productIds) {
        Map<Long, String> mainImages = new HashMap<>();
        for (Long productId : productIds) {
            productImageRepository.findMainImageUrl(productId)
                    .ifPresent(url -> mainImages.put(productId, url));
        }
        return mainImages;
    }
    
    private Map<Long, User> getSellers(List<Long> sellerIds) {
        return userRepository.findAllById(sellerIds).stream()
                .collect(Collectors.toMap(User::getId, user -> user));
    }
    
    private Map<Long, List<String>> getProductTags(List<Long> productIds) {
        Map<Long, List<String>> productTags = new HashMap<>();
        for (Long productId : productIds) {
            List<String> tags = productTagRepository.findTagNamesByProductId(productId);
            productTags.put(productId, tags);
        }
        return productTags;
    }
    
    private Set<Long> getCurrentUserFavorites(Long currentUserId, List<Long> productIds) {
        if (currentUserId == null) {
            return new HashSet<>();
        }
        
        List<Long> userFavorites = productFavoriteRepository.findProductIdsByUserId(currentUserId);
        return productIds.stream()
                .filter(userFavorites::contains)
                .collect(Collectors.toSet());
    }
    
    private Object buildFiltersInfo(ProductQueryRequest request) {
        Map<String, String> filters = new HashMap<>();
        
        if (request.getCategoryId() != null) {
            categoryService.getCategoryById(request.getCategoryId())
                    .ifPresent(category -> filters.put("category", category.getName()));
        }
        
        if (request.getMinPrice() != null || request.getMaxPrice() != null) {
            String priceRange = "";
            if (request.getMinPrice() != null) {
                priceRange += request.getMinPrice();
            }
            priceRange += "-";
            if (request.getMaxPrice() != null) {
                priceRange += request.getMaxPrice();
            }
            filters.put("priceRange", priceRange);
        }
        
        if (StringUtils.hasText(request.getCondition())) {
            Product.ConditionType condition = Product.ConditionType.valueOf(request.getCondition());
            filters.put("condition", condition.getDescription());
        }
        
        if (StringUtils.hasText(request.getProvince()) && StringUtils.hasText(request.getCity())) {
            String location = request.getProvince() + request.getCity();
            if (StringUtils.hasText(request.getDistrict())) {
                location += request.getDistrict();
            }
            filters.put("location", location);
        }
        
        return filters.isEmpty() ? null : filters;
    }
    
    /**
     * 根据商品ID列表批量获取商品摘要信息
     */
    public List<ProductSummaryResponse> getProductSummariesByIds(List<Long> productIds, Long currentUserId) {
        log.info("Getting product summaries by IDs: productIds={}, currentUserId={}", productIds, currentUserId);
        
        if (productIds.isEmpty()) {
            return Collections.emptyList();
        }
        
        // 批量查询商品，保持ID顺序
        List<Product> products = productRepository.findAllById(productIds);
        
        // 使用现有的转换方法
        return convertToSummaryResponses(products, currentUserId);
    }
    
    /**
     * 获取用户发布的商品列表
     */
    public PagedResponse<ProductSummaryResponse> getUserProducts(ProductQueryRequest request, Long userId) {
        log.info("Getting products for user: userId={}, page={}, size={}, status={}", 
                userId, request.getPage(), request.getSize(), request.getStatus());
        
        // 创建分页和排序
        Sort sort = buildSort(request.getSort()); // 使用buildSort方法处理排序
        Pageable pageable = PageRequest.of(request.getPage() - 1, request.getSize(), sort);
        
        // 根据状态筛选查询用户发布的商品
        Page<Product> productPage;
        if (request.getStatus() != null && !"ALL".equals(request.getStatus())) {
            // 按状态筛选
            Product.ProductStatus status = Product.ProductStatus.valueOf(request.getStatus());
            productPage = productRepository.findBySellerIdAndStatusAndDeletedAtIsNull(userId, status, pageable);
        } else {
            // 查询所有状态的商品
            productPage = productRepository.findBySellerIdAndDeletedAtIsNull(userId, pageable);
        }
        
        // 转换为响应对象
        List<ProductSummaryResponse> products = convertToSummaryResponses(productPage.getContent(), userId);
        
        // 构建分页响应
        return PagedResponse.<ProductSummaryResponse>builder()
                .content(products)
                .pagination(PagedResponse.PaginationInfo.builder()
                        .page(request.getPage())
                        .size(request.getSize())
                        .total(productPage.getTotalElements())
                        .totalPages(productPage.getTotalPages())
                        .hasNext(productPage.hasNext())
                        .hasPrevious(productPage.hasPrevious())
                        .isFirst(productPage.isFirst())
                        .isLast(productPage.isLast())
                        .build())
                .build();
    }
}