class TrendEntity {
  final dynamic id;
  final String title;
  final String? type; 
  final int? viewCount;
  final int? likeCount;
  final num? score;
  final String? image;

  const TrendEntity({
    required this.id,
    required this.title,
    this.type,
    this.viewCount,
    this.likeCount,
    this.score,
    this.image,
  });
}

// search times