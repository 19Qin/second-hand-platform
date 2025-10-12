package com.fliliy.secondhand.dto.response;

import com.fliliy.secondhand.dto.ProductDTO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 商品搜索响应
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductSearchResponse {

    /**
     * 搜索结果列表
     */
    private List<ProductDTO> products;

    /**
     * 分页信息
     */
    private PagedResponse.PaginationInfo pagination;

    /**
     * 搜索关键词(可能经过处理)
     */
    private String keyword;

    /**
     * 搜索结果总数
     */
    private Long total;

    /**
     * 是否有更多结果
     */
    private Boolean hasMore;

    /**
     * 搜索耗时(毫秒)
     */
    private Long took;
}
