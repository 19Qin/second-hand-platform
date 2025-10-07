import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_card_skeleton.dart';
import 'product_detail_page.dart';
import '../../../../injection.dart';
import '../../domain/usecases/get_user_favorites.dart';
import '../../domain/usecases/get_product_detail.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<ProductEntity> _favorites = [];
  bool _isLoading = false;
  String? _error;
  String _sortBy = 'time_desc';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getFavorites = ServiceLocator().get<GetUserFavorites>();
      final result = await getFavorites.call(
        status: _status.isEmpty ? '' : _status,
        page: 1,
        size: 20,
        sort: _sortBy,
      );
      
      // 无论是否选择状态筛选，都需要通过商品详情API获取实际状态
      List<ProductEntity> filteredFavorites = await _filterByActualStatus(result.content);
      
      setState(() {
        _favorites = filteredFavorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 通过商品详情API获取实际状态并筛选
  Future<List<ProductEntity>> _filterByActualStatus(List<ProductEntity> products) async {
    final filteredProducts = <ProductEntity>[];
    
    for (final product in products) {
      try {
        // 获取商品详情以获取实际状态
        final getProductDetail = ServiceLocator().get<GetProductDetail>();
        final productDetail = await getProductDetail.call(product.id);
        
        final actualStatus = productDetail.status?.toUpperCase();
        final isActive = actualStatus == 'ACTIVE';
        
        // 根据筛选条件决定是否包含此商品
        bool shouldInclude = false;
        
        if (_status.isEmpty) {
          // All - 包含所有商品
          shouldInclude = true;
        } else if (_status == 'ACTIVE') {
          shouldInclude = isActive;
        } else if (_status == 'INACTIVE') {
          shouldInclude = !isActive;
        }
        
        if (shouldInclude) {
          // 创建一个带有正确状态的商品副本
          final updatedProduct = ProductEntity(
            id: product.id,
            title: product.title,
            price: product.price,
            originalPrice: product.originalPrice,
            discount: product.discount,
            mainImage: product.mainImage,
            condition: product.condition,
            conditionText: product.conditionText,
            locationDisplay: product.locationDisplay,
            distanceKm: product.distanceKm,
            publishedAt: product.publishedAt,
            updatedAt: product.updatedAt,
            seller: product.seller,
            sellerUsername: product.sellerUsername,
            stats: product.stats,
            tags: product.tags,
            status: actualStatus, // 使用从商品详情API获取的实际状态
          );
          filteredProducts.add(updatedProduct);
        }
      } catch (e) {
        // 如果获取商品详情失败，跳过此商品
        print('Failed to get product detail for ${product.id}: $e');
      }
    }
    
    return filteredProducts;
  }

  void _onSortChanged(String? value) {
    if (value != null && value != _sortBy) {
      setState(() {
        _sortBy = value;
      });
      _loadFavorites();
    }
  }

  void _onStatusChanged(String? value) {
    if (value != null && value != _status) {
      setState(() {
        _status = value;
      });
      _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'time_desc',
                child: Text('Latest'),
              ),
              const PopupMenuItem(
                value: 'price_asc',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'price_desc',
                child: Text('Price: High to Low'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _status == '',
                          onTap: () => _onStatusChanged(''),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Active',
                          isSelected: _status == 'ACTIVE',
                          onTap: () => _onStatusChanged('ACTIVE'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Inactive',
                          isSelected: _status == 'INACTIVE',
                          onTap: () => _onStatusChanged('INACTIVE'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Status filter notice
          if (_status.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status == 'ACTIVE' 
                        ? '显示在售中的收藏商品'
                        : '显示已下架或已售出的收藏商品',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _favorites.isEmpty
                        ? _buildEmptyState()
                        : _buildFavoritesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading favorites...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load favorites',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFavorites,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and add products to your favorites!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final product = _favorites[index];
        return _FavoriteCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(productId: product.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF32C286) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = product.mainImage ?? (product.images.isNotEmpty ? product.images.first : null);
    final isNetwork = (img ?? '').startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: img != null
                    ? (isNetwork
                        ? Image.network(
                            img,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Image.asset(
                            img,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ))
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE03636),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.locationDisplay ?? 'Unknown location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.sellerUsername ?? 'Unknown seller',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status indicator
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(product.status),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.favorite,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final actualStatus = status?.toUpperCase();
    if (actualStatus == 'ACTIVE') {
      return Colors.green;
    } else {
      return Colors.grey; // 所有非ACTIVE状态都显示为灰色
    }
  }

  String _getStatusText(String? status) {
    final actualStatus = status?.toUpperCase();
    if (actualStatus == 'ACTIVE') {
      return 'Active';
    } else {
      return 'Inactive'; // 所有非ACTIVE状态都显示为Inactive
    }
  }
}
