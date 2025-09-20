// lib/features/product/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';


// ===== Banner =====
import 'package:mobile/features/banner/presentation/widgets/banner_carousel.dart';
import 'package:mobile/features/banner/presentation/mock/banner_mock.dart';

// ===== Category =====
import 'package:mobile/features/category/domain/entities/category.dart';
import 'package:mobile/features/category/presentation/mock/category_mock.dart';

// ===== Product =====
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:mobile/features/product/presentation/pages/product_detail_page.dart';
import 'package:mobile/features/product/presentation/mock/product_mock.dart';

// ===== Trend =====
import 'package:mobile/features/trend/presentation/widgets/trend_panel.dart';
import 'package:mobile/features/trend/presentation/mock/trend_mock.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.searchController});
  final TextEditingController searchController;

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final List<String> _menu = const ['All', 'Discount', 'Brand', 'Popular', 'Accessories'];
  int _menuIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }


  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});


List<ProductEntity> get _filteredProducts {
  final q = widget.searchController.text.trim().toLowerCase();

  Iterable<ProductEntity> items = mockRecommendedProducts;
    // menu filters
    switch (_menuIndex) {
      case 1:
        items = items.where((p) => (p.originalPrice ?? p.price) > p.price);
        break;
      case 2:
        // keep as-is for mocks; wire to brand later
        break;
      case 3:
        items = items.toList()
          ..sort((a, b) => (b.sellerRating ?? 0).compareTo(a.sellerRating ?? 0));
        break;
      case 4:
        items = items.where(
          (p) => (p.categoryName ?? '').toLowerCase().contains('accessor'),
        );
        break;
      default:
        break;
    }

    // text search
    if (q.isNotEmpty) {
      items = items.where((p) =>
          p.title.toLowerCase().contains(q) ||
          (p.sellerUsername ?? '').toLowerCase().contains(q) ||
          (p.categoryName ?? '').toLowerCase().contains(q));
    }

    return items.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      // Bottom bar + FAB come from your RootShell
      body: CustomScrollView(
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
                    // Categories fill width except a reserved area at right for the Filters button
                    Positioned.fill(
                      right: 96, // reserve space so items don't slide under the button
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
                                  onTap: () => setState(() => _menuIndex = i),
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

                    // Filters button pinned top-right
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Open filters…')),
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
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= LIGHT-GREEN CONTENT =================
          SliverToBoxAdapter(
            child: Container(
              color: cs.primary.withOpacity(0.06),
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

                  // Two category cards (Electronic / Luxury style)
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

          // ================= WATERFALL GRID =================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: 1 + _filteredProducts.length, // +1 for Trend tile
              itemBuilder: (context, i) {
                if (i == 0) {
                  // Trend tile sized to match product card height
                  return _TrendTileCard(
                    child: TrendPanel(
                      items: mockTrends.toList(),
                      onMore: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('More trends…'))),
                      onTap: (e) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Open product ${e.id}'))),
                    ),
                  );
                }
                final p = _filteredProducts[i - 1];
                return _ProductCard(product: p);
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}



/// ------------------------------------------------------------------
/// Category quick cards (two-up row)
/// ------------------------------------------------------------------
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

/// ------------------------------------------------------------------
/// Edge Fade
/// ------------------------------------------------------------------
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

/// ------------------------------------------------------------------
/// Product card
/// ------------------------------------------------------------------
class _ProductCard extends StatefulWidget {
  static const double kTextBlockHeight = 128;
  static double tileHeightForWidth(double w) =>
      w * 3 / 4 /* image 4:3 */ + kTextBlockHeight;

  final ProductEntity product;
  const _ProductCard({super.key, required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  final _wish = WishListStore(); // uses your in-memory singleton
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = _wish.contains(widget.product.id); // id can be int or String
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.product;

    final img = p.mainImage ?? (p.images.isNotEmpty ? p.images.first : null);
    final isNetwork = (img ?? '').startsWith('http');
    final price = p.price;
    final wanted = p.viewCount ?? 0; // demo stat

    return InkWell(
      onTap: () {
        // Navigate to detail page
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
            // ---------- IMAGE with HEART OVERLAY ----------
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavButton(
                      isFav: _isFav,
                      onPressed: () {
                        final nowFav = _wish.toggle(p.id);
                        setState(() => _isFav = nowFav);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nowFav ? 'Added to wishlist' : 'Removed from wishlist',
                            ),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ---------- FIXED-HEIGHT TEXT ----------
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
                          '¥${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFE03636),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$wanted people wanted',
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

/// ------------------------------------------------------------------
/// Trend tile with SAME height as product card (per column width)
/// ------------------------------------------------------------------
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

class _Stars extends StatelessWidget {
  final double rating; // 0..5
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

// ------------------------------------------------------------------
// In-memory wishlist store (demo). Replace with your repo/usecase later.
// ------------------------------------------------------------------
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

// ------------------------------------------------------------------
// RecommendedGrid (unused in current layout; kept for reference)
// ------------------------------------------------------------------
class _RecommendedGrid extends StatefulWidget {
  final List<ProductEntity> items;
  const _RecommendedGrid({required this.items});

  @override
  State<_RecommendedGrid> createState() => _RecommendedGridState();
}

class _RecommendedGridState extends State<_RecommendedGrid> {
  final _wish = WishListStore();

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('No products'));
    }

    final width = MediaQuery.of(context).size.width;
    const crossAxisCount = 2;
    const spacing = 12.0;
    const listOuterPadding = 24.0; // left+right outer padding
    final totalSpacing = spacing * (crossAxisCount - 1);
    final usable = width - listOuterPadding - totalSpacing;
    final tileWidth = usable / crossAxisCount;
    final tileHeight = tileWidth * 1.15;

    return GridView.builder(
      itemCount: widget.items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: tileHeight,
      ),
      itemBuilder: (context, i) {
        final p = widget.items[i];
        final String? img = p.mainImage?.isNotEmpty == true
            ? p.mainImage
            : (p.images.isNotEmpty ? p.images.first : null);
        final bool isNetwork = (img ?? '').startsWith('http');
        final bool isFav = _wish.contains(p.id);

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetailPage(productId: p.id)),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Heart
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: img == null || img.isEmpty
                          ? const ColoredBox(
                              color: Color(0xFFEFEFEF),
                              child: Center(child: Icon(Icons.image_not_supported)),
                            )
                          : isNetwork
                              ? Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: Color(0xFFEFEFEF),
                                    child: Center(child: Icon(Icons.broken_image)),
                                  ),
                                )
                              : Image.asset(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: Color(0xFFEFEFEF),
                                    child: Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _FavButton(
                        isFav: isFav,
                        onPressed: () {
                          final nowFav = _wish.toggle(p.id);
                          setState(() {}); // refresh the tile
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(nowFav
                                  ? 'Added to wishlist'
                                  : 'Removed from wishlist'),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('¥${p.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          if (p.originalPrice != null)
                            Text(
                              '¥${p.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              p.sellerUsername ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(
                            (p.sellerRating ?? 0).toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// Small circular heart button used as an overlay
// ------------------------------------------------------------------

class _FavButton extends StatelessWidget {
  final bool isFav;
  final VoidCallback onPressed;
  const _FavButton({required this.isFav, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.primary; // brand green
    const inactive = Color(0xFF9E9E9E); // grey like the screenshot

    return Semantics(
      button: true,
      toggled: isFav,
      label: isFav ? 'Remove from wishlist' : 'Add to wishlist',
      child: IconButton(
        onPressed: onPressed,
        tooltip: isFav ? 'Remove from wishlist' : 'Add to wishlist',
        splashRadius: 22,
        padding: const EdgeInsets.all(2),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // good tap target
        icon: Icon(
          isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          size: 26,
          color: isFav ? active : inactive,
        ),
      ),
    );
  }
}

