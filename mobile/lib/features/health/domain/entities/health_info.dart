/// Health Check Information Entity
class HealthInfo {
  final String status;
  final String version;
  final String service;
  final int timestamp;

  const HealthInfo({
    required this.status,
    required this.version,
    required this.service,
    required this.timestamp,
  });

  bool get isHealthy {
    final statusLower = status.toLowerCase();
    return statusLower == 'ok' || 
           statusLower == 'healthy' || 
           statusLower == 'up' ||
           statusLower == 'running';
  }
}
