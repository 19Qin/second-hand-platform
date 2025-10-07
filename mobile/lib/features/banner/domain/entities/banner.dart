class BannerEntity {
  final int id;
  final String title;
  final String image;
  final String link;
  final String linkType;
  final int sortOrder;
  final bool isActive;
  final String startTime;
  final String endTime;
  final int clickCount;
  final String createdAt;

  const BannerEntity({
    required this.id,
    required this.title,
    required this.image,
    required this.link,
    required this.linkType,
    required this.sortOrder,
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.clickCount,
    required this.createdAt,
  });
}
