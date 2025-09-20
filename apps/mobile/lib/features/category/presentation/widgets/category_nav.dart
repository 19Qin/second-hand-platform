import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/category.dart';

class CategoryNav extends StatelessWidget {
  final List<CategoryEntity> categories;
  final ValueChanged<int>? onCategorySelected;

  const CategoryNav({
    super.key,
    required this.categories,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (_, i) {
        final cat = categories[i];
        return _CategoryItem(
          category: cat,
          onTap: () => onCategorySelected?.call(cat.id),
          onSubTap: (id) => onCategorySelected?.call(id),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;
  final ValueChanged<int>? onSubTap;

  const _CategoryItem({
    required this.category,
    this.onTap,
    this.onSubTap,
  });

  @override
  Widget build(BuildContext context) {
    final kids = category.children; // simplified
    final hasChildren = kids.isNotEmpty;

    // icon → safe fallback
    final iconUrl = category.icon;
    Widget leading;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      leading = iconUrl.toLowerCase().endsWith('.svg')
          ? SvgPicture.network(
              iconUrl,
              width: 28,
              height: 28,
              placeholderBuilder: (_) => const SizedBox(
                width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : Image.network(
              iconUrl,
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 28),
            );
    } else {
      leading = const Icon(Icons.category, size: 28);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leading,
          title: Text(category.name),
          subtitle: category.productCount != null ? Text('${category.productCount} items') : null,
          onTap: onTap,
        ),
        if (hasChildren)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kids
                .map((c) => ActionChip(
                      label: Text(c.name),
                      onPressed: () => onSubTap?.call(c.id),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
