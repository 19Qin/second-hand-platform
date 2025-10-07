import '../../domain/entities/health_info.dart';

/// Health Check Data Model
class HealthModel {
  final String status;
  final String version;
  final String service;
  final int timestamp;

  const HealthModel({
    required this.status,
    required this.version,
    required this.service,
    required this.timestamp,
  });

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    // Handle timestamp, could be string or integer
    int parsedTimestamp;
    final timestampValue = json['timestamp'];
    if (timestampValue is String) {
      // If it's a string format time, convert to millisecond timestamp
      try {
        final dateTime = DateTime.parse(timestampValue);
        parsedTimestamp = dateTime.millisecondsSinceEpoch;
      } catch (e) {
        parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
      }
    } else if (timestampValue is int) {
      parsedTimestamp = timestampValue;
    } else {
      parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
    }

    return HealthModel(
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '1.0.0',
      service: json['service'] as String? ?? 'flifi-api',
      timestamp: parsedTimestamp,
    );
  }

  HealthInfo toEntity() {
    return HealthInfo(
      status: status,
      version: version,
      service: service,
      timestamp: timestamp,
    );
  }
}
