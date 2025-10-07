import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserProfileEntity> getUserProfile() async {
    final model = await _remoteDataSource.getUserProfile();
    return model.toEntity();
  }

  @override
  Future<UserProfileEntity> updateUserProfile(Map<String, dynamic> updateData) async {
    final model = await _remoteDataSource.updateUserProfile(updateData);
    return model.toEntity();
  }
}

