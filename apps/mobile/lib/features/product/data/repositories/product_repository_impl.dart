import 'package:mobile/features/product/domain/entities/product.dart' as domain;
import 'package:mobile/features/product/domain/repositories/product_repository.dart';

import 'package:mobile/features/product/data/datasources/product_remote_ds.dart';
import 'package:mobile/features/product/data/models/product_list_response_model.dart';
import 'package:mobile/features/product/data/models/product_model.dart';

/// Concrete repo that converts data models to domain entities.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remote;

  ProductRepositoryImpl({required this.remote});

  @override
  Future<ProductPage> getProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? keyword,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? location,
    int? sellerId,
  }) async {
    final ProductListResponseModel res = await remote.getProducts(
      page: page,
      size: size,
      categoryId: categoryId,
      keyword: keyword,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: sort,
      location: location,
      sellerId: sellerId,
    );

    // Map models → domain entities
    final items = res.items.map((m) => m.toDomain()).toList();

    // Prefer a robust flag if your model exposes it; else derive from pages.
    final hasNext = res.pagination.hasNext;

    return ProductPage(items: items, hasNext: hasNext);
  }

  @override
  Future<domain.Product> getProduct(int id) async {
    final ProductModel model = await remote.getProduct(id);
    return model.toDomain();
  }
}

/// Mapping from data model to domain entity.
/// Adjust fields if your domain entity differs.
extension ProductModelMapper on ProductModel {
  domain.Product toDomain() {
    return domain.Product(
      id: id,
      title: title,
      description: description,
      price: price,
      originalPrice: originalPrice,
      discount: discount,
      mainImage: mainImage,
      images: images,
      condition: condition,
      conditionText: conditionText,
      category: domain.CategoryInfo(
        id: category.id,
        name: category.name,
      ),
      seller: domain.SellerInfo(
        id: seller.id,
        name: seller.name,
        // Add other seller fields if present in domain.
      ),
      location: domain.LocationInfo(
        city: location.city,
        // Add lat/lng/state/country if your domain has them.
      ),
      tags: tags,
      status: status,
      viewCount: viewCount,
      favoriteCount: favoriteCount,
      chatCount: chatCount,
      publishedAt: publishedAt,
      updatedAt: updatedAt,
      isFavorited: isFavorited,
      distance: distance,
    );
  }
}
