class UserProfileEntity {
  final String id;
  final String username;
  final String mobile;
  final String? email;
  final String avatar;
  final int gender;
  final DateTime? birthday;
  final String? location;
  final String? bio;
  final bool verified;
  final DateTime registeredAt;
  final DateTime lastLoginAt;
  final UserStatsEntity stats;
  final UserRatingEntity rating;
  final UserPreferencesEntity preferences;

  const UserProfileEntity({
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
}

class UserStatsEntity {
  final int publishedCount;
  final int activeCount;
  final int soldCount;
  final int boughtCount;
  final int favoriteCount;
  final int chatCount;
  final int points;
  final int credits;

  const UserStatsEntity({
    required this.publishedCount,
    required this.activeCount,
    required this.soldCount,
    required this.boughtCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.points,
    required this.credits,
  });
}

class UserRatingEntity {
  final double average;
  final int total;
  final Map<String, int> distribution;

  const UserRatingEntity({
    required this.average,
    required this.total,
    required this.distribution,
  });
}

class UserPreferencesEntity {
  final bool pushNotification;
  final bool emailNotification;
  final bool showMobile;
  final bool showLocation;

  const UserPreferencesEntity({
    required this.pushNotification,
    required this.emailNotification,
    required this.showMobile,
    required this.showLocation,
  });
}

