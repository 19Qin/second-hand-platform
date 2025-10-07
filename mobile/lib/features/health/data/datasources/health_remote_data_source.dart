import '../../../../core/network/api_client.dart';
import '../models/health_model.dart';

/// Health Check Remote Data Source
abstract class HealthRemoteDataSource {
  Future<HealthModel> getHealth();
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  final ApiClient _apiClient;

  HealthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<HealthModel> getHealth() async {
    final response = await _apiClient.get<HealthModel>(
      'health',
      fromJson: (json) => HealthModel.fromJson(json as Map<String, dynamic>),
    );
    return response;
  }
}
