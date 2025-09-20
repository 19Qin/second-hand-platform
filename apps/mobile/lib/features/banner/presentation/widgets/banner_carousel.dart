import 'package:flutter/material.dart';
import '../../domain/entities/banner.dart' as ent;

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.items,
    this.height = 180,
    this.onTap,
  });

  final List<ent.BannerEntity> items;
  final double height;
  final void Function(ent.BannerEntity item)? onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return GestureDetector(
                onTap: widget.onTap == null ? null : () => widget.onTap!(item),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl, // <-- matches the entity above
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            child: _PillDotsIndicator(count: widget.items.length, index: _index),
          ),
        ],
      ),
    );
  }
}

class _PillDotsIndicator extends StatelessWidget {
  const _PillDotsIndicator({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 26 : 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(active ? 0.95 : 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
