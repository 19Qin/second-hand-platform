package com.fliliy.secondhand.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.domain.Page;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PagedResponse<T> {
    
    private List<T> content;
    private PaginationInfo pagination;
    private Object filters; // 当前筛选条件汇总（可选）
    
    // 简化构造函数
    public PagedResponse(List<T> content, int page, int size, long total, int totalPages, boolean hasNext) {
        this.content = content;
        this.pagination = new PaginationInfo();
        this.pagination.setPage(page);
        this.pagination.setSize(size);
        this.pagination.setTotal(total);
        this.pagination.setTotalPages(totalPages);
        this.pagination.setHasNext(hasNext);
        this.pagination.setHasPrevious(page > 1);
        this.pagination.setIsFirst(page == 1);
        this.pagination.setIsLast(!hasNext);
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PaginationInfo {
        private Integer page;
        private Integer size;
        private Long total;
        private Integer totalPages;
        private Boolean hasNext;
        private Boolean hasPrevious;
        private Boolean isFirst;
        private Boolean isLast;
    }
    
    // 静态工厂方法
    public static <T> PagedResponse<T> of(List<T> content, Page<?> page) {
        PagedResponse<T> response = new PagedResponse<>();
        response.setContent(content);
        
        PaginationInfo pagination = new PaginationInfo();
        pagination.setPage(page.getNumber() + 1); // 转换为1开始的页码
        pagination.setSize(page.getSize());
        pagination.setTotal(page.getTotalElements());
        pagination.setTotalPages(page.getTotalPages());
        pagination.setHasNext(page.hasNext());
        pagination.setHasPrevious(page.hasPrevious());
        pagination.setIsFirst(page.isFirst());
        pagination.setIsLast(page.isLast());
        
        response.setPagination(pagination);
        return response;
    }
    
    // 带筛选条件的工厂方法
    public static <T> PagedResponse<T> of(List<T> content, Page<?> page, Object filters) {
        PagedResponse<T> response = of(content, page);
        response.setFilters(filters);
        return response;
    }
}