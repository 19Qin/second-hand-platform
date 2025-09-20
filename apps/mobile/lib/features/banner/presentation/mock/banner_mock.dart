import 'package:mobile/features/banner/domain/entities/banner.dart';

final List<BannerEntity> mockBanners = <BannerEntity>[
  const BannerEntity(
    id: '1',
    imageUrl: 'assets/images/promotion_banner.png',
    title: 'New Year Sale',
    link: '/promo/new-year',
  ),
  const BannerEntity(
    id: '2',
    imageUrl: 'assets/images/promotion_banner.png',
    title: 'Hot Products',
    link: '/products/hot',
  ),
  const BannerEntity(
    id: '3',
    imageUrl: 'assets/images/promotion_banner.png',
    title: 'Limited Offer',
    link: '/promo/limited',
  ),
];
