import 'package:flutter/material.dart';
import '../widgets/banner_carousel.dart';

class BannerPage extends StatelessWidget {
  const BannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Banner Carousel")),
      body: const BannerCarousel(),
    );
  }
}
