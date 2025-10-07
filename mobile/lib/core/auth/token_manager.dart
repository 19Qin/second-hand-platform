import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Token管理器，负责本地Token的存储和管理
class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpirationKey = 'token_expiration';
  static const String _userInfoKey = 'user_info';

  static TokenManager? _instance;
  SharedPreferences? _prefs;

  TokenManager._();

  static TokenManager get instance {
    _instance ??= TokenManager._();
    return _instance!;
  }

  /// 初始化SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 保存Token信息
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    Map<String, dynamic>? userInfo,
  }) async {
    await init();
    
    await _prefs!.setString(_accessTokenKey, accessToken);
    await _prefs!.setString(_refreshTokenKey, refreshToken);
    
    // 保存用户信息
    if (userInfo != null) {
      await _prefs!.setString(_userInfoKey, json.encode(userInfo));
    }
    
    // 计算过期时间（当前时间 + 有效期 - 5分钟缓冲）
    final expirationTime = DateTime.now().add(
      Duration(seconds: expiresIn - 300), // 提前5分钟过期
    );
    await _prefs!.setInt(_tokenExpirationKey, expirationTime.millisecondsSinceEpoch);
  }

  /// 获取访问Token
  Future<String?> getAccessToken() async {
    await init();
    return _prefs!.getString(_accessTokenKey);
  }

  /// 获取刷新Token
  Future<String?> getRefreshToken() async {
    await init();
    return _prefs!.getString(_refreshTokenKey);
  }

  /// 检查Token是否过期
  Future<bool> isTokenExpired() async {
    await init();
    
    final expirationTime = _prefs!.getInt(_tokenExpirationKey);
    if (expirationTime == null) return true;
    
    final expiration = DateTime.fromMillisecondsSinceEpoch(expirationTime);
    return DateTime.now().isAfter(expiration);
  }

  /// 检查是否有有效Token
  Future<bool> hasValidToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    
    return !(await isTokenExpired());
  }


  /// 检查是否需要刷新Token（提前10分钟刷新）
  Future<bool> needsRefresh() async {
    await init();
    
    final expirationTime = _prefs!.getInt(_tokenExpirationKey);
    if (expirationTime == null) return true;
    
    final expiration = DateTime.fromMillisecondsSinceEpoch(expirationTime);
    final refreshThreshold = DateTime.now().add(const Duration(minutes: 10));
    
    return refreshThreshold.isAfter(expiration);
  }

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    await init();
    
    final userInfoString = _prefs!.getString(_userInfoKey);
    if (userInfoString == null) return null;
    
    try {
      return json.decode(userInfoString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 清除所有Token和用户信息
  Future<void> clearTokens() async {
    await init();
    
    await _prefs!.remove(_accessTokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_tokenExpirationKey);
    await _prefs!.remove(_userInfoKey);
  }
}
