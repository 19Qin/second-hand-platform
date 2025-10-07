import '../entities/health_info.dart';

/// Health Check Repository Interface
abstract class HealthRepository {
  Future<HealthInfo> getHealth();
}
