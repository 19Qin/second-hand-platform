import '../entities/health_info.dart';
import '../repositories/health_repository.dart';

/// Get Health Check Use Case
class GetHealth {
  final HealthRepository _repository;

  GetHealth(this._repository);

  Future<HealthInfo> call() async {
    return await _repository.getHealth();
  }
}
