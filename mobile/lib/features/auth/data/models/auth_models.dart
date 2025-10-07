import '../../domain/entities/auth_entities.dart';

/// 短信验证码响应模型
class SmsResponseModel {
  final String smsId;
  final int expireTime;

  SmsResponseModel({
    required this.smsId,
    required this.expireTime,
  });

  factory SmsResponseModel.fromJson(Map<String, dynamic> json) {
    return SmsResponseModel(
      smsId: json['smsId'] as String,
      expireTime: json['expireTime'] as int,
    );
  }

  SmsResponseEntity toEntity() => SmsResponseEntity(
        smsId: smsId,
        expireTime: expireTime,
      );
}

/// 用户基本信息模型
class UserModel {
  final String userId;
  final String username;
  final String mobile;
  final String? email;
  final String avatar;
  final bool verified;
  final String status;
  final List<String> permissions;
  final String? lastLoginAt;
  final String? registeredAt;
  final bool? needBindMobile; // 后端返回的额外字段

  UserModel({
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
    this.needBindMobile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        userId: json['userId'] as String,
        username: json['username'] as String,
        mobile: json['mobile'] as String,
        email: json['email'] as String?,
        avatar: json['avatar'] as String? ?? 'https://cdn.fliliy.com/avatar/default.png',
        verified: json['verified'] as bool? ?? false,  // 后端可能不返回这个字段
        status: json['status'] as String? ?? 'NORMAL',  // 后端可能不返回这个字段
        permissions: (json['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [], // 后端可能不返回这个字段
        lastLoginAt: json['lastLoginAt'] as String?,
        registeredAt: json['registeredAt'] as String?,
        needBindMobile: json['needBindMobile'] as bool?,  // 后端实际返回的字段
      );
    } catch (e) {
      print('❌ UserModel.fromJson error: $e');
      print('📋 JSON data: $json');
      rethrow;
    }
  }

  UserEntity toEntity() => UserEntity(
        userId: userId,
        username: username,
        mobile: mobile,
        email: email,
        avatar: avatar,
        verified: verified,
        status: status,
        permissions: permissions,
        lastLoginAt: lastLoginAt != null ? DateTime.tryParse(lastLoginAt!) : null,
        registeredAt: registeredAt != null ? DateTime.tryParse(registeredAt!) : null,
      );
}

/// 认证响应模型（登录/注册）
class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;

  AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      refreshExpiresIn: json['refreshExpiresIn'] as int? ?? (json['expiresIn'] as int) * 10, // 后端没有这个字段，设置为accessToken的10倍
    );
  }

  AuthResponseEntity toEntity() => AuthResponseEntity(
        user: user.toEntity(),
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        refreshExpiresIn: refreshExpiresIn,
      );
}

/// Token验证模型
class TokenValidationModel {
  final bool valid;
  final String? userId;
  final int? expiresIn;
  final bool needRefresh;
  final List<String> permissions;

  TokenValidationModel({
    required this.valid,
    this.userId,
    this.expiresIn,
    required this.needRefresh,
    required this.permissions,
  });

  factory TokenValidationModel.fromJson(Map<String, dynamic> json) {
    return TokenValidationModel(
      valid: json['valid'] as bool,
      userId: json['userId'] as String?,
      expiresIn: json['expiresIn'] as int?,
      needRefresh: json['needRefresh'] as bool,
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  TokenValidationEntity toEntity() => TokenValidationEntity(
        valid: valid,
        userId: userId,
        expiresIn: expiresIn,
        needRefresh: needRefresh,
        permissions: permissions,
      );
}

/// 用户详细信息模型
class UserDetailModel {
  final String userId;
  final String username;
  final String mobile;
  final String? email;
  final String avatar;
  final int gender;
  final String? birthday;
  final String? location;
  final String? bio;
  final bool verified;
  final String status;
  final String registeredAt;
  final String lastLoginAt;
  final UserStatsModel stats;
  final UserRatingModel rating;
  final List<String> permissions;
  final UserSettingsModel settings;

  UserDetailModel({
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

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    return UserDetailModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String,
      gender: json['gender'] as int,
      birthday: json['birthday'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      verified: json['verified'] as bool,
      status: json['status'] as String,
      registeredAt: json['registeredAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String,
      stats: UserStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      rating: UserRatingModel.fromJson(json['rating'] as Map<String, dynamic>),
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      settings:
          UserSettingsModel.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  UserDetailEntity toEntity() => UserDetailEntity(
        userId: userId,
        username: username,
        mobile: mobile,
        email: email,
        avatar: avatar,
        gender: gender,
        birthday: birthday != null ? DateTime.tryParse(birthday!) : null,
        location: location,
        bio: bio,
        verified: verified,
        status: status,
        registeredAt: DateTime.parse(registeredAt),
        lastLoginAt: DateTime.parse(lastLoginAt),
        stats: stats.toEntity(),
        rating: rating.toEntity(),
        permissions: permissions,
        settings: settings.toEntity(),
      );
}

/// 用户统计信息模型
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
      publishedCount: json['publishedCount'] as int,
      activeCount: json['activeCount'] as int,
      soldCount: json['soldCount'] as int,
      boughtCount: json['boughtCount'] as int,
      favoriteCount: json['favoriteCount'] as int,
      chatCount: json['chatCount'] as int,
      points: json['points'] as int,
      credits: json['credits'] as int,
    );
  }

  UserStatsEntity toEntity() => UserStatsEntity(
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

/// 用户评分模型
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
    final dist = json['distribution'] as Map<String, dynamic>? ?? {};
    return UserRatingModel(
      average: (json['average'] as num).toDouble(),
      total: json['total'] as int,
      distribution: dist.map((key, value) => MapEntry(key, value as int)),
    );
  }

  UserRatingEntity toEntity() => UserRatingEntity(
        average: average,
        total: total,
        distribution: distribution,
      );
}

/// 用户设置模型
class UserSettingsModel {
  final bool pushNotification;
  final bool emailNotification;
  final bool showMobile;
  final bool showLocation;

  UserSettingsModel({
    required this.pushNotification,
    required this.emailNotification,
    required this.showMobile,
    required this.showLocation,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      pushNotification: json['pushNotification'] as bool,
      emailNotification: json['emailNotification'] as bool,
      showMobile: json['showMobile'] as bool,
      showLocation: json['showLocation'] as bool,
    );
  }

  UserSettingsEntity toEntity() => UserSettingsEntity(
        pushNotification: pushNotification,
        emailNotification: emailNotification,
        showMobile: showMobile,
        showLocation: showLocation,
      );
}
