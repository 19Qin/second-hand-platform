import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';

/// Product Card Skeleton
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SkeletonLoader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: SkeletonBox(
                  height: double.infinity,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            
            // Text area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const SkeletonText(height: 16, width: double.infinity),
                  const SizedBox(height: 6),
                  
                  // Price row
                  Row(
                    children: [
                      const SkeletonText(height: 14, width: 60),
                      const SizedBox(width: 8),
                      const SkeletonText(height: 12, width: 80),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Seller info row
                  Row(
                    children: [
                      const SkeletonBox(width: 14, height: 14),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: SkeletonText(height: 12, width: double.infinity),
                      ),
                      const SizedBox(width: 6),
                      const SkeletonBox(width: 40, height: 12),
                    ],
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

/// Product Grid Skeleton
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: itemCount,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      ),
    );
  }
}
