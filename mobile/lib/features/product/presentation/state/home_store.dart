import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/usecases/get_products.dart';
import '../mock/product_mock.dart';
import 'home_state.dart';

/// Home Page State Management
class HomeStore extends ChangeNotifier {
  final GetProducts _getProducts;
  HomeState _state = HomeState.initial();

  HomeStore(this._getProducts);

  HomeState get state => _state;
  bool get isLoading => _state.isLoading;
  bool get hasError => _state.hasError;

  /// Load Home Page Products
  Future<void> loadProducts({
    bool refresh = false,
    String? sort,
    int? categoryId,
  }) async {
    if (refresh) {
      _updateState(_state.copyWith(
        status: HomeStatus.loading,
        currentPage: 1,
      ));
    } else {
      if (_state.isLoading || !_state.hasMore) return;
      _updateState(_state.copyWith(status: HomeStatus.loading));
    }

    try {
      if (AppConfig.useMock) {
        // 使用Mock数据
        await _loadMockProducts(refresh);
      } else {
        // 使用真实API
        await _loadRealProducts(refresh, sort, categoryId);
      }
    } on ApiException catch (e) {
      _updateState(_state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Loading failed: ${e.toString()}',
      ));
    }
  }

  /// Load Mock Data
  Future<void> _loadMockProducts(bool refresh) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final products = refresh ? mockRecommendedProducts : _state.products + mockRecommendedProducts;
    
    _updateState(_state.copyWith(
      status: HomeStatus.success,
      products: products,
      hasMore: false, // Mock data does not support pagination
      errorMessage: null,
    ));
  }

  /// Load Real API Data
  Future<void> _loadRealProducts(bool refresh, String? sort, int? categoryId) async {
    final page = refresh ? 1 : _state.currentPage + 1;
    
    final result = await _getProducts(
      page: page,
      size: AppConfig.defaultPageSize,
      sort: sort,
      categoryId: categoryId,
    );

    final newProducts = refresh 
        ? result.items 
        : _state.products + result.items;

    _updateState(_state.copyWith(
      status: HomeStatus.success,
      products: newProducts,
      hasMore: result.pagination.hasNext,
      currentPage: page,
      errorMessage: null,
    ));
  }

  /// Refresh Data
  Future<void> refresh({String? sort, int? categoryId}) async {
    await loadProducts(refresh: true, sort: sort, categoryId: categoryId);
  }

  /// Load More
  Future<void> loadMore({String? sort, int? categoryId}) async {
    await loadProducts(refresh: false, sort: sort, categoryId: categoryId);
  }

  /// Retry
  Future<void> retry({String? sort, int? categoryId}) async {
    await loadProducts(refresh: true, sort: sort, categoryId: categoryId);
  }

  void _updateState(HomeState newState) {
    _state = newState;
    notifyListeners();
  }
}
