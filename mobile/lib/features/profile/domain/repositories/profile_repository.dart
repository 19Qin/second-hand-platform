import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileEntity> getUserProfile();
  Future<UserProfileEntity> updateUserProfile(Map<String, dynamic> updateData);
}

