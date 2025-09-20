// lib/features/product/presentation/pages/product_detail_page.dart
import 'package:flutter/material.dart';

// ===== Entity + mock lookup for the demo =====
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:mobile/features/product/presentation/mock/product_mock.dart';

// ===== Local wishlist store (in-memory demo) =====
import 'package:mobile/features/product/presentation/state/wishlist_store.dart';

const kBrandGreen = Color(0xFF32C286); // <-- use this brand green

class ProductDetailPage extends StatefulWidget {
  final dynamic productId;
  final ProductEntity? initial;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initial,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _wish = WishListStore(); // not shown in UI now, but ready to use
  late Future<ProductEntity> _future;
  int _page = 0; // current image page

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProductEntity> _load() async {
    // Uses product_mock.dart
    if (widget.initial != null) return widget.initial!;
    final key = widget.productId.toString();
    return mockRecommendedProducts.firstWhere(
      (p) => p.id.toString() == key,
      orElse: () => mockRecommendedProducts.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the page in a Theme that sets primary to kBrandGreen
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: kBrandGreen),
      ),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;

          return FutureBuilder<ProductEntity>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final product = snap.data!;
              final images = _imagesOf(product);
              final price = product.price;
              final reviewsCount = (product.viewCount ?? 0).toInt();

              return Scaffold(
                backgroundColor: Colors.white,

                body: SafeArea(
                  top: false, // overlays inside the gallery use safe-top padding
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      // ===== Square hero gallery with overlays =====
                      _Gallery(
                        images: images,
                        page: _page,
                        onPageChanged: (i) => setState(() => _page = i),

                        // top-left: back button overlayed on the image
                        topLeft: _IconBubble(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),

                        // top-right: Heart + Share
                        topRight: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HeartButton(
                              isFav: _wish.contains(widget.productId),
                              onTap: () {
                                final v = _wish.toggle(widget.productId);
                                setState(() {});
                                _snack(v
                                    ? 'Added to wishlist'
                                    : 'Removed from wishlist');
                              },
                            ),
                            const SizedBox(width: 8),
                            _IconBubble(
                              icon: Icons.ios_share_rounded,
                              onTap: () => _snack('Share'),
                            ),
                          ],
                        ),

                        // bottom-right: Album X/N badge
                        bottomRight: _AlbumBadge(
                          current: _page + 1,
                          total: images.length,
                        ),
                      ),

                      // ===== Price (left) + reviews (right) =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                        child: Row(
                          children: [
                            Text(
                              _money(price),
                              style: const TextStyle(
                                color: Color(0xFFE03636),
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_formatCount(reviewsCount)} Review',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Optional chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(text: 'Fixed-price item'),
                            _Chip(text: 'Points Redeemed'),
                          ],
                        ),
                      ),

                      // ===== Product name with HOT badge =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('HOT!',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== Product Detail square (light grey background) =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ProductDetailCard(product: product),
                      ),
                    ],
                  ),
                ),

                // ===== Bottom actions =====
                bottomNavigationBar: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _snack('Buy now'),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              'Buy now',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _snack('Contact seller'),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Contact seller',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<String> _imagesOf(ProductEntity p) {
    final pics = <String>[];
    if ((p.mainImage ?? '').isNotEmpty) pics.add(p.mainImage!);
    pics.addAll(p.images.where((e) => e.isNotEmpty));
    if (pics.isEmpty) pics.add('');
    return pics;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/* ─────────────────────────────  GALLERY  ───────────────────────────── */

class _Gallery extends StatelessWidget {
  final List<String> images;
  final int page;
  final ValueChanged<int> onPageChanged;
  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomRight;

  const _Gallery({
    required this.images,
    required this.page,
    required this.onPageChanged,
    this.topLeft,
    this.topRight,
    this.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: page);
    final cs = Theme.of(context).colorScheme;
    final double safeTop = MediaQuery.of(context).padding.top;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, i) {
              final url = images[i];
              if (url.isEmpty) return ColoredBox(color: cs.primary.withOpacity(.10));
              final isNet = url.startsWith('http');
              return isNet
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: cs.primary.withOpacity(.10)),
                    )
                  : Image.asset(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: cs.primary.withOpacity(.10)),
                    );
            },
          ),

          if (topLeft != null)
            Positioned(
              left: 8,
              top: safeTop + 8, // stay below notch/status bar
              child: topLeft!,
            ),

          if (topRight != null)
            Positioned(
              right: 8,
              top: safeTop + 8,
              child: topRight!,
            ),

          if (bottomRight != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: bottomRight!,
            ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBubble({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool isFav;
  final VoidCallback onTap;
  const _HeartButton({required this.isFav, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: isFav ? cs.primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _AlbumBadge extends StatelessWidget {
  final int current;
  final int total;
  const _AlbumBadge({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary, width: 1.6),
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Album $current/$total',
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/* ─────────────────────────────  PRODUCT DETAIL CARD  ───────────────────────────── */

class _ProductDetailCard extends StatefulWidget {
  final ProductEntity product;
  const _ProductDetailCard({required this.product});

  @override
  State<_ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<_ProductDetailCard> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // These three quick attributes appear on top, with a chevron to another page
    final brand = 'SNOY';
    final color = 'White';
    final model = 'Sony PlayStation 5 Blu-Ray Edition';

    final kv = <_KV>[
      const _KV('Usage time', '3 Years'),
      const _KV('Product Condition', 'Slight scratches (signs of damage)'),
      const _KV('Warranty', 'Already expired', valueColor: Colors.teal),
      const _KV('Functional', 'Running well', valueColor: Colors.teal),
    ];

    final description =
        'This handle has some minor wear from normal use. Fully functional and tested. '
        'Includes original controller and power cable. No box.';

    const panelColor = Color(0xFFF4F5F7); // solid light grey square

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                const Text('Product Detail',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Following information was filled by seller',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),

          // Brand / Color / Model + chevron (tap to go to attributes page)
          InkWell(
            onTap: () => _snack(context, 'See all product attributes'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(child: _TripleCell(label: 'Brand', value: brand)),
                  Expanded(child: _TripleCell(label: 'Color', value: color)),
                  Expanded(
                    child: _TripleCell(label: 'Model', value: model, maxLines: 1),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),

          const Divider(height: 16, thickness: 0.7),

          // Key-value rows
          for (final r in kv) _KvRow(r),

          // Description with expand arrow on the same line (right aligned)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 120,
                  child: Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnimatedCrossFade(
                          firstChild: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(description),
                          crossFadeState: _descExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 160),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(_descExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded),
                        onPressed: () =>
                            setState(() => _descExpanded = !_descExpanded),
                        tooltip: _descExpanded ? 'Collapse' : 'Expand',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
}

class _TripleCell extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  const _TripleCell({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _KV {
  final String key;
  final String value;
  final Color? valueColor;
  const _KV(this.key, this.value, {this.valueColor});
}

class _KvRow extends StatelessWidget {
  final _KV row;
  const _KvRow(this.row);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: TextStyle(color: row.valueColor ?? cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────  HELPERS  ───────────────────────────── */

String _money(double v) {
  return '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
