import 'package:flutter/foundation.dart';
import '../../domain/usecases/get_health.dart';
import '../../../../core/network/api_exception.dart';
import 'health_state.dart';

/// Health Check State Management
class HealthStore extends ChangeNotifier {
  final GetHealth _getHealth;
  HealthState _state = HealthState.initial();

  HealthStore(this._getHealth);

  HealthState get state => _state;
  bool get isHealthy => _state.isHealthy;
  bool get hasError => _state.hasError;


  /// Check Service Health Status
  Future<void> checkHealth() async {
    if (kDebugMode) {
      print('🏥 Starting health check...');
    }
    
    _updateState(_state.copyWith(status: HealthStatus.loading));

    try {
      final healthInfo = await _getHealth();
      
      if (kDebugMode) {
        print('✅ Health check successful: ${healthInfo.status}');
      }
      
      _updateState(_state.copyWith(
        status: HealthStatus.success,
        healthInfo: healthInfo,
        errorMessage: null,
      ));
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('❌ API exception: ${e.code} - ${e.message}');
      }
      
      _updateState(_state.copyWith(
        status: HealthStatus.error,
        errorMessage: 'API error: ${e.message}',
      ));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unknown error: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      _updateState(_state.copyWith(
        status: HealthStatus.error,
        errorMessage: 'Service connection failed: ${e.toString()}',
      ));
    }
  }

  /// Retry Health Check
  Future<void> retry() async {
    await checkHealth();
  }

  void _updateState(HealthState newState) {
    _state = newState;
    notifyListeners();
  }
}
