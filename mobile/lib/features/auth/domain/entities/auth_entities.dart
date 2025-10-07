/// 短信验证码响应实体
class SmsResponseEntity {
  final String smsId;
  final int expireTime;

  const SmsResponseEntity({
    required this.smsId,
    required this.expireTime,
  });
}

/// 用户基本信息实体
class UserEntity {
  final String userId;
  final String username;
  final String mobile;
  final String? email;
  final String avatar;
  final bool verified;
  final String status;
  final List<String> permissions;
  final DateTime? lastLoginAt;
  final DateTime? registeredAt;

  const UserEntity({
    required this.userId,
    required this.username,
    required this.mobile,
    this.email,
    required this.avatar,
    required this.verified,
    required this.status,
    required this.permissions,
    this.lastLoginAt,
    this.registeredAt,
  });
}

/// 认证响应实体（登录/注册）
class AuthResponseEntity {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;

  const AuthResponseEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
  });
}

/// Token验证实体
class TokenValidationEntity {
  final bool valid;
  final String? userId;
  final int? expiresIn;
  final bool needRefresh;
  final List<String> permissions;

  const TokenValidationEntity({
    required this.valid,
    this.userId,
    this.expiresIn,
    required this.needRefresh,
    required this.permissions,
  });
}

/// 用户详细信息实体
class UserDetailEntity {
  final String userId;
  final String username;
  final String mobile;
  final String? email;
  final String avatar;
  final int gender;
  final DateTime? birthday;
  final String? location;
  final String? bio;
  final bool verified;
  final String status;
  final DateTime registeredAt;
  final DateTime lastLoginAt;
  final UserStatsEntity stats;
  final UserRatingEntity rating;
  final List<String> permissions;
  final UserSettingsEntity settings;

  const UserDetailEntity({
    required this.userId,
    required this.username,
    required this.mobile,
    this.email,
    required this.avatar,
    required this.gender,
    this.birthday,
    this.location,
    this.bio,
    required this.verified,
    required this.status,
    required this.registeredAt,
    required this.lastLoginAt,
    required this.stats,
    required this.rating,
    required this.permissions,
    required this.settings,
  });
}

/// 用户统计信息实体
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

/// 用户评分实体
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

/// 用户设置实体
class UserSettingsEntity {
  final bool pushNotification;
  final bool emailNotification;
  final bool showMobile;
  final bool showLocation;

  const UserSettingsEntity({
    required this.pushNotification,
    required this.emailNotification,
    required this.showMobile,
    required this.showLocation,
  });
}
