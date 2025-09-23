class BannerEntity {
  final String id;
  final String imageUrl;
  final String? title;
  final String? link;

  const BannerEntity({
    required this.id,
    required this.imageUrl,
    this.title,
    this.link,
  });
}
