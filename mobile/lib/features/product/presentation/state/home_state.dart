import '../../domain/entities/product.dart';

/// Home Page Status
enum HomeStatus { initial, loading, success, error }

class HomeState {
  final HomeStatus status;
  final List<ProductEntity> products;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;

  const HomeState({
    required this.status,
    this.products = const [],
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
  });

  HomeState.initial() : this(status: HomeStatus.initial);

  HomeState copyWith({
    HomeStatus? status,
    List<ProductEntity>? products,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return HomeState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isLoading => status == HomeStatus.loading;
  bool get hasError => status == HomeStatus.error;
  bool get isEmpty => products.isEmpty && status == HomeStatus.success;
}
