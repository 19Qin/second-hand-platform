import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/banner.dart';

part 'banner_model.g.dart';

@JsonSerializable()
class BannerModel extends BannerEntity {
  final int sortOrder;
  final bool isActive;
  final String startTime;
  final String endTime;
  final int clickCount;
  final String createdAt;

  BannerModel({
    required int id,
    required String title,
    required String image,
    required String link,
    required String linkType,
    required this.sortOrder,
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.clickCount,
    required this.createdAt,
  }) : super(
          id: id,
          title: title,
          image: image,
          link: link,
          linkType: linkType,
        );

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}
