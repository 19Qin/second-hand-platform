import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<UserProfileModel> updateUserProfile(Map<String, dynamic> updateData);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileModel> getUserProfile() async {
    try {
      final response = await _apiClient.get('/user/profile');
      
      if (response['code'] == 200) {
        return UserProfileModel.fromJson(response['data']);
      } else {
        throw ServerException(
          code: response['code'],
          message: response['message'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Failed to get user profile',
        details: e.toString(),
      );
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await _apiClient.put('/user/profile', body: updateData);
      
      // 处理空响应的情况（更新成功但返回空响应体）
      if (response == null) {
        // 重新获取用户资料以返回最新的用户信息
        return await getUserProfile();
      }
      
      if (response['code'] == 200) {
        // 如果响应包含数据，返回更新后的用户信息
        if (response['data'] != null) {
          return UserProfileModel.fromJson(response['data']);
        } else {
          // 如果响应成功但没有数据，重新获取用户资料
          return await getUserProfile();
        }
      } else {
        throw ServerException(
          code: response['code'],
          message: response['message'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Failed to update user profile',
        details: e.toString(),
      );
    }
  }
}
