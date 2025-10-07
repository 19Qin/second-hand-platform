import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository _repository;

  GetUserProfileUseCase(this._repository);

  Future<UserProfileEntity> call() async {
    return await _repository.getUserProfile();
  }
}

