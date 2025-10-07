import '../repositories/product_repository.dart';

class ToggleFavorite {
  final ProductRepository repository;

  ToggleFavorite(this.repository);

  Future<ToggleFavoriteResponse> call(String productId) async {
    return await repository.toggleFavorite(productId);
  }
}

class ToggleFavoriteResponse {
  final bool isFavorited;
  final int favoriteCount;

  ToggleFavoriteResponse({
    required this.isFavorited,
    required this.favoriteCount,
  });
}


