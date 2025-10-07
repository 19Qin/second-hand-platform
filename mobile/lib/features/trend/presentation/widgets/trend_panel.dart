// lib/features/trend/presentation/widgets/trend_panel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/trend.dart';

/// Helper that tries to read common fields from any TrendEntity shape.
class _TrendFields {
  static String? nameOf(TrendEntity e) {
    final d = e as dynamic;
    try { final v = d.name as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.title as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.productName as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.label as String?; if (_nz(v)) return v; } catch (_) {}
    return null;
  }

  static String? categoryOf(TrendEntity e) {
    final d = e as dynamic;
    try { final v = d.categoryName as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.category as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.type as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.productType as String?; if (_nz(v)) return v; } catch (_) {}
    return null;
  }

  static String? imageOf(TrendEntity e) {
    final d = e as dynamic;
    try { final v = d.imageUrl as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.image as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.thumbnail as String?; if (_nz(v)) return v; } catch (_) {}
    try { final v = d.mainImage as String?; if (_nz(v)) return v; } catch (_) {}
    try {
      final imgs = d.images as List?;
      if (imgs != null && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is String && _nz(first)) return first;
      }
    } catch (_) {}
    return null;
  }

  static bool _nz(String? s) => s != null && s.trim().isNotEmpty;
}

class TrendPanel extends StatelessWidget {
  final List<TrendEntity> items;
  final VoidCallback? onMore;
  final void Function(TrendEntity)? onTap;

  const TrendPanel({
    super.key,
    required this.items,
    this.onMore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = items.length <= 3 ? items : items.sublist(0, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: only "Trend"
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text('Trend', style: Theme.of(context).textTheme.titleMedium),
        ),

        // Body list (fills available height in the card)
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            itemCount: top3.length,
            itemBuilder: (context, i) => _TrendRow(
              rank: i + 1,
              trend: top3[i],
              onTap: onTap,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          ),
        ),

        // Bottom "more >" (optional)
        if (onMore != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onMore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'more ›',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  final int rank; // 1..N
  final TrendEntity trend;
  final void Function(TrendEntity)? onTap;

  const _TrendRow({
    required this.rank,
    required this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final title = _TrendFields.nameOf(trend) ?? 'Item';
    final category = _TrendFields.categoryOf(trend) ?? '—';
    final imageUrl = _TrendFields.imageOf(trend);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap == null ? null : () => onTap!(trend),
      child: Row(
        children: [
          // Thumbnail + "TopX" chip
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _Thumb(url: imageUrl),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Top$rank',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Two lines: name + type/category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primary.withOpacity(.12);

    return SizedBox(
      width: 64,
      height: 64,
      child: (url ?? '').isEmpty
          ? ColoredBox(color: bg)
          : (url!.startsWith('http')
              ? Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: bg),
                )
              : Image.asset(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: bg),
                )),
    );
  }
}
