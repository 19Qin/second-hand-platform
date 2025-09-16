import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final img = product.mainImage ?? (product.images.isNotEmpty ? product.images.first : null);

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: img == null || img.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFEFEFEF),
                      child: Icon(Icons.image_not_supported),
                    )
                  : Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEFEFEF),
                        child: Icon(Icons.broken_image),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('¥${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (product.originalPrice != null)
                          Text(
                            '¥${product.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        if (product.discount != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${product.discount}% OFF',
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          product.locationDistrict ?? product.locationCity ?? '-',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        const Icon(Icons.visibility, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text('${product.viewCount ?? 0}', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text('${product.favoriteCount ?? 0}', style: const TextStyle(color: Colors.grey)),
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
