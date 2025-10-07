import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';

// Core
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../injection.dart';

// Banner
import '../../../banner/presentation/widgets/banner_carousel.dart';
import '../../../banner/presentation/mock/banner_mock.dart';

// Category
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/mock/category_mock.dart';

// Product
import '../../domain/entities/product.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../widgets/product_card_skeleton.dart';
import '../state/home_store.dart';
import '../state/home_state.dart';
import 'product_detail_page.dart';

// Trend
import '../../../trend/presentation/widgets/trend_panel.dart';
import '../../../trend/presentation/mock/trend_mock.dart';


// Favorites
import 'favorites_page.dart';

class HomePageNew extends StatefulWidget {
  const HomePageNew({super.key, required this.searchController});
  final TextEditingController searchController;

  @override
  State<HomePageNew> createState() => HomePageNewState();
}

class HomePageNewState extends State<HomePageNew> {
  final List<String> _menu = const ['All', 'Discount', 'Brand', 'Popular', 'Accessories', 'Luxuries', 'Electronic'];
  int _menuIndex = 0;
  late HomeStore _homeStore;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _homeStore = ServiceLocator().get<HomeStore>();
    _homeStore.addListener(_onHomeStateChanged);
    widget.searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeStore.loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _homeStore.removeListener(_onHomeStateChanged);
    widget.searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onHomeStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() => setState(() {});
  
  // 公共刷新方法
  void refreshHome() {
    _homeStore.loadProducts(refresh: true);
  }


  void _showFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FavoritesPage(),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _homeStore.loadMore();
    }
  }

  void _onMenuChanged(int index) {
    setState(() => _menuIndex = index);
    
    // Load different data based on menu selection
    String? sort;
    switch (index) {
      case 1: // Discount
        sort = 'discount_desc';
        break;
      case 3: // Popular
        sort = 'popular';
        break;
      default:
        sort = 'created_at_desc';
    }
    
    _homeStore.refresh(sort: sort);
  }

  List<ProductEntity> get _filteredProducts {
    final query = widget.searchController.text.trim().toLowerCase();
    var products = _homeStore.state.products;

    // Menu filtering
    switch (_menuIndex) {
      case 1: // Discount
        products = products.where((p) => (p.originalPrice ?? 0) > p.price).toList();
        break;
      case 4: // Accessories
        products = products.where((p) => 
          (p.categoryName ?? '').toLowerCase().contains('accessor')).toList();
        break;
    }

    // Search filtering
    if (query.isNotEmpty) {
      products = products.where((p) =>
          p.title.toLowerCase().contains(query) ||
          (p.sellerUsername ?? '').toLowerCase().contains(query) ||
          (p.categoryName ?? '').toLowerCase().contains(query)).toList();
    }

    return products;
  }

  // Helper method to get special category count
  int _getSpecialCategoryCount() {
    final selectedCategory = _menu[_menuIndex];
    print('🔍 Selected category: $selectedCategory, index: $_menuIndex');
    if (selectedCategory == 'Luxuries' || selectedCategory == 'Electronic') {
      print('✅ Special category detected: $selectedCategory');
      return 1; // Show one special category image
    }
    return 0;
  }

  // Build special category card
  Widget _buildSpecialCategoryCard(int index) {
    final selectedCategory = _menu[_menuIndex];
    print('🎨 Building special category card for: $selectedCategory');
    
    if (selectedCategory == 'Luxuries') {
      return _SpecialCategoryCard(
        imagePath: 'assets/images/luxuries_showcase.png',
        title: 'Luxury Collection',
        subtitle: 'Premium brands & exclusive items',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Luxury collection coming soon!')),
        ),
      );
    } else if (selectedCategory == 'Electronic') {
      return _SpecialCategoryCard(
        imagePath: 'assets/images/electronics_showcase.png',
        title: 'Electronics Hub',
        subtitle: 'Latest tech & gadgets',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Electronics collection coming soon!')),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = _homeStore.state;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 RefreshIndicator triggered');
          await _homeStore.refresh();
        },
        color: const Color(0xFF32C286), // Set refresh indicator color
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(), // Ensure always scrollable
          slivers: [
            // ================= WHITE MENU BAR =================
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      // Categories
                      Positioned.fill(
                        right: 96,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: _menu.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 18),
                                itemBuilder: (context, i) {
                                  final bool selected = _menuIndex == i;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _onMenuChanged(i),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _menu[i],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            curve: Curves.easeOut,
                                            height: 3,
                                            width: selected ? 20 : 0,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF32C286),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Edge fades
                      const Positioned(left: 0, top: 0, bottom: 0, child: _EdgeFade(width: 18)),
                      const Positioned(right: 0, top: 0, bottom: 0, child: _EdgeFade(width: 18, reverse: true)),

                      // Filters button
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 0,
                        child: TextButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Filter feature under development...')),
                          ),
                          icon: const Icon(Icons.filter_list, color: Colors.black),
                          label: const Text(
                            'Filters',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ================= LIGHT-GREEN CONTENT =================
            SliverToBoxAdapter(
              child: Container(
                color: colorScheme.primary.withOpacity(0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: BannerCarousel(
                            items: mockBanners,
                            height: 180,
                            onTap: (b) {
                              // handle navigation if b.link != null
                            },
                          ),
                        ),
                      ),
                    ),

                    // Category header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Category', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),

                    // Two category cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _TwoCategoryCards(
                        left: _pickCategoryByName(mockCategories, '电子') ??
                            _toQuickCategory(mockCategories.first),
                        right: _pickCategoryByName(mockCategories, '服装') ??
                            (mockCategories.length > 1
                                ? _toQuickCategory(mockCategories[1])
                                : _toQuickCategory(mockCategories.first)),
                        onShopTap: (id) => ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Shop $id'))),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Recommended header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Recommended', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ================= PRODUCTS GRID =================
            _buildProductsGrid(state),

            // Loading more indicator
            if (state.isLoading && state.products.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Ensure enough space to trigger pull-to-refresh
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                height: 100, // Minimum height to ensure scrolling
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(HomeState state) {
    // Error state
    if (state.hasError && state.products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorState.network(
            message: state.errorMessage,
            onAction: () => _homeStore.retry(),
          ),
        ),
      );
    }

    // Loading state
    if (state.isLoading && state.products.isEmpty) {
      return const ProductGridSkeleton(itemCount: 6);
    }

    final filteredProducts = _filteredProducts;

    // Empty state
    if (filteredProducts.isEmpty && state.status == HomeStatus.success) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.search_off,
            title: 'No products found',
            subtitle: 'Try adjusting search criteria or browse other categories',
          ),
        ),
      );
    }

    // Product grid
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: (1 + filteredProducts.length + _getSpecialCategoryCount()).toInt(), // +1 for Trend tile + special categories
        itemBuilder: (context, i) {
          if (i == 0) {
            // Trend tile
            return _TrendTileCard(
              child: TrendPanel(
                items: mockTrends.toList(),
                onMore: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('More trends...'))),
                onTap: (e) => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Open product ${e.id}'))),
              ),
            );
          }
          
          // Check if we should show special category images
          final specialCategoryIndex = i - 1;
          if (specialCategoryIndex < _getSpecialCategoryCount()) {
            return _buildSpecialCategoryCard(specialCategoryIndex);
          }
          
          final productIndex = i - 1 - _getSpecialCategoryCount();
          final product = filteredProducts[productIndex];
          return _ProductCard(product: product);
        },
      ),
    );
  }
}

// ================= Reuse existing components =================

class _EdgeFade extends StatelessWidget {
  final double width;
  final bool reverse;
  const _EdgeFade({this.width = 18, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    return IgnorePointer(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
            end: reverse ? Alignment.centerLeft : Alignment.centerRight,
            colors: [bg, bg.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}

class _TwoCategoryCards extends StatelessWidget {
  final _QuickCategory left, right;
  final void Function(int id) onShopTap;

  const _TwoCategoryCards({
    required this.left,
    required this.right,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _CategoryCard(item: left, onShop: () => onShopTap(left.id))),
        const SizedBox(width: 12),
        Expanded(child: _CategoryCard(item: right, onShop: () => onShopTap(right.id))),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _QuickCategory item;
  final VoidCallback onShop;
  const _CategoryCard({required this.item, required this.onShop});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(color: cs.primary.withOpacity(.12)),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(item.subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onShop,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('Shop ›'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCategory {
  final int id;
  final String title;
  final String subtitle;
  const _QuickCategory({required this.id, required this.title, required this.subtitle});
}

_QuickCategory _toQuickCategory(CategoryEntity c) =>
    _QuickCategory(id: c.id, title: c.name, subtitle: 'Up to 15% off');

_QuickCategory? _pickCategoryByName(List<CategoryEntity> list, String contains) {
  try {
    final c = list.firstWhere((e) => e.name.contains(contains));
    return _QuickCategory(id: c.id, title: c.name, subtitle: '100% Authentic');
  } catch (_) {
    return null;
  }
}

class _TrendTileCard extends StatelessWidget {
  final Widget child;
  const _TrendTileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final h = _ProductCard.tileHeightForWidth(box.maxWidth);
        return SizedBox(
          height: h,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black87, width: 1.6),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  static const double kTextBlockHeight = 128;
  static double tileHeightForWidth(double w) =>
      w * 3 / 4 /* image 4:3 */ + kTextBlockHeight;

  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late bool _isFav;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFav = widget.product.stats?.isFavorited ?? false;
  }

  Future<void> _toggleFavorite(String productId) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final toggleFavorite = ServiceLocator().get<ToggleFavorite>();
      final response = await toggleFavorite.call(productId);
      
      setState(() {
        _isFav = response.isFavorited;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isFavorited ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.product;

    final img = p.mainImage ?? (p.images.isNotEmpty ? p.images.first : null);
    final isNetwork = (img ?? '').startsWith('http');
    final price = p.price;
    final wanted = p.viewCount ?? 0;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(productId: p.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with heart overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(productId: p.id),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: img == null || img.isEmpty
                          ? ColoredBox(color: cs.primary.withOpacity(.12))
                          : isNetwork
                              ? Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      ColoredBox(color: cs.primary.withOpacity(.12)),
                                )
                              : Image.asset(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      ColoredBox(color: cs.primary.withOpacity(.12)),
                                ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child:                     _FavButton(
                      isFav: _isFav,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : () => _toggleFavorite(p.id),
                    ),
                  ),
                ],
              ),
            ),

            // Fixed-height text
            SizedBox(
              height: _ProductCard.kTextBlockHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFE03636),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$wanted people viewed',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.sellerUsername ?? 'Shop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: cs.onSurface),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Stars(rating: p.sellerRating ?? 4.0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});
  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < full; i++) const Icon(Icons.star, size: 14, color: Colors.amber),
        if (half) const Icon(Icons.star_half, size: 14, color: Colors.amber),
        for (int i = 0; i < empty; i++) const Icon(Icons.star_border, size: 14, color: Colors.amber),
      ],
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool isFav;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _FavButton({
    required this.isFav, 
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.primary;
    const inactive = Color(0xFF9E9E9E);

    return Semantics(
      button: true,
      toggled: isFav,
      label: isFav ? 'Remove from wishlist' : 'Add to wishlist',
      child: IconButton(
        onPressed: onPressed,
        tooltip: isFav ? 'Remove from wishlist' : 'Add to wishlist',
        splashRadius: 22,
        padding: const EdgeInsets.all(2),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFav ? active : inactive,
                ),
              ),
            )
          : Icon(
              isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              size: 26,
              color: isFav ? active : inactive,
            ),
      ),
    );
  }
}

// WishListStore (reused from original)
class WishListStore {
  WishListStore._();
  static final WishListStore _i = WishListStore._();
  factory WishListStore() => _i;

  final Set<String> _ids = <String>{};

  bool contains(dynamic id) => _ids.contains(id.toString());

  bool toggle(dynamic id) {
    final key = id.toString();
    if (_ids.remove(key)) return false;
    _ids.add(key);
    return true;
  }

  Set<String> get ids => _ids;
}

// Global method to show "Coming Soon" dialog
void _showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF32C286).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 40,
                color: Color(0xFF32C286),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Online transaction and shipping features are under development, stay tuned!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF32C286),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

}

// Special category card widget
class _SpecialCategoryCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SpecialCategoryCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
