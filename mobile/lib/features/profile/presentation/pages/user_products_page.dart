import 'package:flutter/material.dart';
import '../../../../injection.dart';
import '../../domain/usecases/get_user_products_usecase.dart';
import '../../domain/entities/user_product_entity.dart';

class UserProductsPage extends StatefulWidget {
  final String? initialStatus;
  
  const UserProductsPage({super.key, this.initialStatus});

  @override
  _UserProductsPageState createState() => _UserProductsPageState();
}

class _UserProductsPageState extends State<UserProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GetUserProductsUseCase _getUserProductsUseCase = ServiceLocator().get<GetUserProductsUseCase>();
  
  List<UserProductEntity> _allProducts = [];
  List<UserProductEntity> _activeProducts = [];
  List<UserProductEntity> _soldProducts = [];
  List<UserProductEntity> _inactiveProducts = [];
  
  bool _isLoading = true;
  String? _error;
  UserProductsSummaryEntity? _summary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set initial tab based on status
    if (widget.initialStatus != null) {
      switch (widget.initialStatus!.toLowerCase()) {
        case 'active':
          _tabController.index = 1;
          break;
        case 'sold':
          _tabController.index = 2;
          break;
        case 'inactive':
          _tabController.index = 3;
          break;
        default:
          _tabController.index = 0; // All
          break;
      }
    }
    
    _loadUserProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all products (no status parameter for all)
      final allResponse = await _getUserProductsUseCase(
        status: null, // No status parameter for all products
        page: 1,
        size: 50, // API limit is 50
        sort: 'time_desc',
      );

      // Load products by status
      final activeResponse = await _getUserProductsUseCase(
        status: 'ACTIVE',
        page: 1,
        size: 50,
        sort: 'time_desc',
      );

      final soldResponse = await _getUserProductsUseCase(
        status: 'SOLD',
        page: 1,
        size: 50,
        sort: 'time_desc',
      );

      final inactiveResponse = await _getUserProductsUseCase(
        status: 'INACTIVE',
        page: 1,
        size: 50,
        sort: 'time_desc',
      );

      // Debug: Print product data
      print('🔍 All products count: ${allResponse.products.length}');
      print('🔍 Active products count: ${activeResponse.products.length}');
      print('🔍 Sold products count: ${soldResponse.products.length}');
      print('🔍 Inactive products count: ${inactiveResponse.products.length}');
      
      for (var product in allResponse.products) {
        print('🔍 Product: ${product.title}, Status: ${product.status}, StatusText: ${product.statusText}');
      }

      // Filter products by actual status since backend filtering is not working properly
      final allProducts = allResponse.products;
      final activeProducts = allProducts.where((p) => p.status == 'ACTIVE').toList();
      final soldProducts = allProducts.where((p) => p.status == 'SOLD').toList();
      final inactiveProducts = allProducts.where((p) => p.status == 'INACTIVE').toList();

      // Create summary with actual counts from the filtered products
      final summary = UserProductsSummaryEntity(
        total: allProducts.length,
        active: activeProducts.length,
        sold: soldProducts.length,
        inactive: inactiveProducts.length,
      );

      setState(() {
        _allProducts = allProducts;
        _activeProducts = activeProducts;
        _soldProducts = soldProducts;
        _inactiveProducts = inactiveProducts;
        _summary = summary;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Products',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF32C286),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF32C286),
          tabs: [
            Tab(text: 'All (${_summary?.total ?? 0})'),
            Tab(text: 'Active (${_summary?.active ?? 0})'),
            Tab(text: 'Sold (${_summary?.sold ?? 0})'),
            Tab(text: 'Inactive (${_summary?.inactive ?? 0})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32C286)),
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductList(_allProducts),
                    _buildProductList(_activeProducts),
                    _buildProductList(_soldProducts),
                    _buildProductList(_inactiveProducts),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF32C286),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<UserProductEntity> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Products',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go publish your first product',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserProducts,
      color: const Color(0xFF32C286),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(UserProductEntity product) {
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
        onTap: () => _onProductTap(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.mainImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Product information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      '¥${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF32C286),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Status label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(product.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(product.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 统计信息
                    Row(
                      children: [
                        _buildStatItem(Icons.visibility, product.stats.viewCount),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.favorite, product.stats.favoriteCount),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.chat, product.stats.chatCount),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              PopupMenuButton<String>(
                onSelected: (action) => _onActionSelected(action, product),
                itemBuilder: (context) => [
                  if (product.actions.contains('EDIT'))
                    const PopupMenuItem(
                      value: 'EDIT',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                  if (product.actions.contains('VIEW_CHATS'))
                    const PopupMenuItem(
                      value: 'VIEW_CHATS',
                      child: Row(
                        children: [
                          Icon(Icons.chat, size: 18),
                          SizedBox(width: 8),
                          Text('查看聊天'),
                        ],
                      ),
                    ),
                  if (product.actions.contains('PROMOTE'))
                    const PopupMenuItem(
                      value: 'PROMOTE',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, size: 18),
                          SizedBox(width: 8),
                          Text('推广'),
                        ],
                      ),
                    ),
                  if (product.actions.contains('DELETE'))
                    const PopupMenuItem(
                      value: 'DELETE',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF32C286);
      case 'SOLD':
        return const Color(0xFF2196F3);
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _onProductTap(UserProductEntity product) {
    // 跳转到商品详情页
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => ProductDetailPage(productId: product.id),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看商品: ${product.title}')),
    );
  }

  void _onActionSelected(String action, UserProductEntity product) {
    switch (action) {
      case 'EDIT':
        _editProduct(product);
        break;
      case 'VIEW_CHATS':
        _viewChats(product);
        break;
      case 'PROMOTE':
        _promoteProduct(product);
        break;
      case 'DELETE':
        _deleteProduct(product);
        break;
    }
  }

  void _editProduct(UserProductEntity product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('编辑商品: ${product.title}')),
    );
  }

  void _viewChats(UserProductEntity product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看聊天: ${product.title}')),
    );
  }

  void _promoteProduct(UserProductEntity product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('推广商品: ${product.title}')),
    );
  }

  void _deleteProduct(UserProductEntity product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除商品"${product.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('删除商品: ${product.title}')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}


