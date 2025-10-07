import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository _repository;

  UpdateUserProfileUseCase(this._repository);

  Future<UserProfileEntity> call(Map<String, dynamic> updateData) async {
    return await _repository.updateUserProfile(updateData);
  }
}

