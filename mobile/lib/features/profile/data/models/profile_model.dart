import '../../domain/entities/profile_entity.dart';

class UserProfileModel {
  final String id;
  final String username;
  final String mobile;
  final String? email;
  final String avatar;
  final int gender;
  final String? birthday;
  final String? location;
  final String? bio;
  final bool verified;
  final String registeredAt;
  final String lastLoginAt;
  final UserStatsModel stats;
  final UserRatingModel rating;
  final UserPreferencesModel preferences;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.mobile,
    this.email,
    required this.avatar,
    required this.gender,
    this.birthday,
    this.location,
    this.bio,
    required this.verified,
    required this.registeredAt,
    required this.lastLoginAt,
    required this.stats,
    required this.rating,
    required this.preferences,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String,
      gender: (json['gender'] as num?)?.toInt() ?? 0,
      birthday: json['birthday'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      verified: json['verified'] as bool? ?? false,
      registeredAt: json['registeredAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String,
      stats: UserStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      rating: json['rating'] != null 
          ? UserRatingModel.fromJson(json['rating'] as Map<String, dynamic>)
          : UserRatingModel(average: 0.0, total: 0, distribution: {}),
      preferences: UserPreferencesModel.fromJson(json['preferences'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'mobile': mobile,
      'email': email,
      'avatar': avatar,
      'gender': gender,
      'birthday': birthday,
      'location': location,
      'bio': bio,
      'verified': verified,
      'registeredAt': registeredAt,
      'lastLoginAt': lastLoginAt,
      'stats': stats.toJson(),
      'rating': rating.toJson(),
      'preferences': preferences.toJson(),
    };
  }

  UserProfileEntity toEntity() {
    return UserProfileEntity(
      id: id,
      username: username,
      mobile: mobile,
      email: email,
      avatar: avatar,
      gender: gender,
      birthday: birthday != null ? DateTime.parse(birthday!) : null,
      location: location,
      bio: bio,
      verified: verified,
      registeredAt: DateTime.parse(registeredAt),
      lastLoginAt: DateTime.parse(lastLoginAt),
      stats: stats.toEntity(),
      rating: rating.toEntity(),
      preferences: preferences.toEntity(),
    );
  }
}

class UserStatsModel {
  final int publishedCount;
  final int activeCount;
  final int soldCount;
  final int boughtCount;
  final int favoriteCount;
  final int chatCount;
  final int points;
  final int credits;

  UserStatsModel({
    required this.publishedCount,
    required this.activeCount,
    required this.soldCount,
    required this.boughtCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.points,
    required this.credits,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      boughtCount: (json['boughtCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      chatCount: (json['chatCount'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publishedCount': publishedCount,
      'activeCount': activeCount,
      'soldCount': soldCount,
      'boughtCount': boughtCount,
      'favoriteCount': favoriteCount,
      'chatCount': chatCount,
      'points': points,
      'credits': credits,
    };
  }

  UserStatsEntity toEntity() {
    return UserStatsEntity(
      publishedCount: publishedCount,
      activeCount: activeCount,
      soldCount: soldCount,
      boughtCount: boughtCount,
      favoriteCount: favoriteCount,
      chatCount: chatCount,
      points: points,
      credits: credits,
    );
  }
}

class UserRatingModel {
  final double average;
  final int total;
  final Map<String, int> distribution;

  UserRatingModel({
    required this.average,
    required this.total,
    required this.distribution,
  });

  factory UserRatingModel.fromJson(Map<String, dynamic> json) {
    return UserRatingModel(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      distribution: json['distribution'] != null 
          ? Map<String, int>.from(json['distribution'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'total': total,
      'distribution': distribution,
    };
  }

  UserRatingEntity toEntity() {
    return UserRatingEntity(
      average: average,
      total: total,
      distribution: distribution,
    );
  }
}

class UserPreferencesModel {
  final bool pushNotification;
  final bool emailNotification;
  final bool showMobile;
  final bool showLocation;

  UserPreferencesModel({
    required this.pushNotification,
    required this.emailNotification,
    required this.showMobile,
    required this.showLocation,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      pushNotification: json['pushNotification'] as bool? ?? true,
      emailNotification: json['emailNotification'] as bool? ?? false,
      showMobile: json['showMobile'] as bool? ?? false,
      showLocation: json['showLocation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotification': pushNotification,
      'emailNotification': emailNotification,
      'showMobile': showMobile,
      'showLocation': showLocation,
    };
  }

  UserPreferencesEntity toEntity() {
    return UserPreferencesEntity(
      pushNotification: pushNotification,
      emailNotification: emailNotification,
      showMobile: showMobile,
      showLocation: showLocation,
    );
  }
}

