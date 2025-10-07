import '../../domain/usecases/toggle_favorite.dart';

class ToggleFavoriteResponseModel {
  final bool isFavorited;
  final int favoriteCount;

  ToggleFavoriteResponseModel({
    required this.isFavorited,
    required this.favoriteCount,
  });

  factory ToggleFavoriteResponseModel.fromJson(Map<String, dynamic> json) {
    return ToggleFavoriteResponseModel(
      isFavorited: json['isFavorited'] as bool? ?? false,
      favoriteCount: json['favoriteCount'] as int? ?? 0,
    );
  }

  ToggleFavoriteResponse toEntity() => ToggleFavoriteResponse(
        isFavorited: isFavorited,
        favoriteCount: favoriteCount,
      );
}


