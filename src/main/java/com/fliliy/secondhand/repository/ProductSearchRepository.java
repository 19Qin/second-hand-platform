package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.document.ProductDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 商品搜索Repository
 */
@Repository
public interface ProductSearchRepository extends ElasticsearchRepository<ProductDocument, Long> {

    /**
     * 根据标题搜索
     */
    List<ProductDocument> findByTitleContaining(String title);

    /**
     * 根据分类查询
     */
    List<ProductDocument> findByCategoryId(Integer categoryId);

    /**
     * 根据城市查询
     */
    List<ProductDocument> findByCity(String city);

    /**
     * 根据状态查询
     */
    List<ProductDocument> findByStatus(String status);
}
