import '../../domain/entities/health_info.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_remote_data_source.dart';

/// Health Check Repository Implementation
class HealthRepositoryImpl implements HealthRepository {
  final HealthRemoteDataSource _remoteDataSource;

  HealthRepositoryImpl(this._remoteDataSource);

  @override
  Future<HealthInfo> getHealth() async {
    final model = await _remoteDataSource.getHealth();
    return model.toEntity();
  }
}
