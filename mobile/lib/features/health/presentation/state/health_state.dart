import '../../domain/entities/health_info.dart';

/// Health Check Status
enum HealthStatus { initial, loading, success, error }

class HealthState {
  final HealthStatus status;
  final HealthInfo? healthInfo;
  final String? errorMessage;

  const HealthState({
    required this.status,
    this.healthInfo,
    this.errorMessage,
  });

  HealthState.initial() : this(status: HealthStatus.initial);

  HealthState copyWith({
    HealthStatus? status,
    HealthInfo? healthInfo,
    String? errorMessage,
  }) {
    return HealthState(
      status: status ?? this.status,
      healthInfo: healthInfo ?? this.healthInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isHealthy => healthInfo?.isHealthy ?? false;
  bool get isLoading => status == HealthStatus.loading;
  bool get hasError => status == HealthStatus.error;
}
