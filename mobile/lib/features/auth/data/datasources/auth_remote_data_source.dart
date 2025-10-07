import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  /// 发送短信验证码
  Future<SmsResponseModel> sendSmsCode({
    required String mobile,
    required String type,
  });

  /// 用户注册
  Future<AuthResponseModel> register({
    required String username,
    required String mobile,
    required String password,
    required String confirmPassword,
    required String smsCode,
    required String smsId,
    required bool agreeTerms,
  });

  /// 密码登录
  Future<AuthResponseModel> loginWithPassword({
    required String mobile,
    required String password,
    bool rememberMe = false,
  });

  /// 验证码登录
  Future<AuthResponseModel> loginWithSms({
    required String mobile,
    required String smsCode,
    required String smsId,
  });

  /// Token验证
  Future<TokenValidationModel> validateToken();

  /// 刷新Token
  Future<AuthResponseModel> refreshToken({
    required String refreshToken,
  });

  /// 退出登录
  Future<void> logout({
    String? refreshToken,
  });

  /// 获取当前用户信息
  Future<UserDetailModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<SmsResponseModel> sendSmsCode({
    required String mobile,
    required String type,
  }) async {
    final response = await _apiClient.post<SmsResponseModel>(
      'auth/sms/send',
      body: {
        'mobile': mobile,
        'type': type,
      },
      fromJson: (json) => SmsResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }

  @override
  Future<AuthResponseModel> register({
    required String username,
    required String mobile,
    required String password,
    required String confirmPassword,
    required String smsCode,
    required String smsId,
    required bool agreeTerms,
  }) async {
    final response = await _apiClient.post<AuthResponseModel>(
      'auth/register',
      body: {
        'username': username,
        'mobile': mobile,
        'password': password,
        'confirmPassword': confirmPassword,
        'smsCode': smsCode,
        'smsId': smsId,
        'agreeTerms': agreeTerms,
      },
      fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }

  @override
  Future<AuthResponseModel> loginWithPassword({
    required String mobile,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _apiClient.post<AuthResponseModel>(
      'auth/login/password',
      body: {
        'mobile': mobile,
        'password': password,
        'rememberMe': rememberMe,
      },
      fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }

  @override
  Future<AuthResponseModel> loginWithSms({
    required String mobile,
    required String smsCode,
    required String smsId,
  }) async {
    final response = await _apiClient.post<AuthResponseModel>(
      'auth/login/sms',
      body: {
        'mobile': mobile,
        'smsCode': smsCode,
        'smsId': smsId,
      },
      fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }

  @override
  Future<TokenValidationModel> validateToken() async {
    final response = await _apiClient.get<TokenValidationModel>(
      'auth/validate',
      fromJson: (json) => TokenValidationModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }

  @override
  Future<AuthResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiClient.post<AuthResponseModel>(
      'auth/token/refresh',
      body: {
        'refreshToken': refreshToken,
      },
      fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }

  @override
  Future<void> logout({
    String? refreshToken,
  }) async {
    await _apiClient.post<void>(
      'auth/logout',
      body: refreshToken != null ? {'refreshToken': refreshToken} : null,
    );
  }

  @override
  Future<UserDetailModel> getCurrentUser() async {
    final response = await _apiClient.get<UserDetailModel>(
      'auth/me',
      fromJson: (json) => UserDetailModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }
}
