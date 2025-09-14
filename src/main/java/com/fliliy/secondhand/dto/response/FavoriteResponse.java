package com.fliliy.secondhand.dto.response;

import lombok.Data;

@Data
public class FavoriteResponse {
    
    private Boolean isFavorited;
    private Integer favoriteCount;
}