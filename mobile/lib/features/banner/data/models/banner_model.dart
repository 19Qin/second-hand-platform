import '../../domain/entities/banner.dart';

class BannerModel {
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

  BannerModel({
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

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        id: json['id'] as int,
        title: json['title'] as String,
        image: json['image'] as String,
        link: json['link'] as String,
        linkType: json['linkType'] as String,
        sortOrder: json['sortOrder'] as int,
        isActive: json['isActive'] as bool,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        clickCount: json['clickCount'] as int,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'link': link,
        'linkType': linkType,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'startTime': startTime,
        'endTime': endTime,
        'clickCount': clickCount,
        'createdAt': createdAt,
      };

  BannerEntity toEntity() => BannerEntity(
        id: id,
        title: title,
        image: image,
        link: link,
        linkType: linkType,
        sortOrder: sortOrder,
        isActive: isActive,
        startTime: startTime,
        endTime: endTime,
        clickCount: clickCount,
        createdAt: createdAt,
      );
}
