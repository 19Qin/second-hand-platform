import '../../domain/entities/trend.dart';

class TrendModel extends TrendEntity {
  const TrendModel({
    required super.id,
    required super.title,
    super.type,
    super.viewCount,
    super.likeCount,
    super.score,
    super.image,
    this.rank,
  });

  /// rank coming from the API
  final int? rank;

  factory TrendModel.fromJson(Map<String, dynamic> json) => TrendModel(
        id: json['id'],
        title: json['title'] ?? '',
        type: json['type'],
        viewCount: json['viewCount'],
        likeCount: json['likeCount'],
        score: json['score'],
        image: json['image'],
        rank: json['rank'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'score': score,
        'image': image,
        'rank': rank,
      };
}
