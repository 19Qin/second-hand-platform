import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../pages/product_detail_page.dart';
import 'product_card.dart';

class ProductListView extends StatelessWidget {
  final List<ProductEntity> items;
  const ProductListView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No products'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final p = items[i];
        return ProductCard(
          product: p,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProductDetailPage(productId: p.id),
            ));
          },
        );
      },
    );
  }
}
