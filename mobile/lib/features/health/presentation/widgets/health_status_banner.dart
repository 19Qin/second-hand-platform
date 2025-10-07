import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../injection.dart';
import '../state/health_store.dart';
import '../state/health_state.dart';

/// Health Status Banner Component
class HealthStatusBanner extends StatefulWidget {
  const HealthStatusBanner({super.key});

  @override
  State<HealthStatusBanner> createState() => _HealthStatusBannerState();
}

class _HealthStatusBannerState extends State<HealthStatusBanner> {
  late HealthStore _healthStore;

  @override
  void initState() {
    super.initState();
    _healthStore = ServiceLocator().get<HealthStore>();
    _healthStore.addListener(_onHealthStateChanged);
  }

  @override
  void dispose() {
    _healthStore.removeListener(_onHealthStateChanged);
    super.dispose();
  }

  void _onHealthStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _healthStore.state;

    // 服务健康时不显示横幅
    if (state.status == HealthStatus.success && state.isHealthy) {
      return const SizedBox.shrink();
    }

    // 初始状态时不显示
    if (state.status == HealthStatus.initial) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: _getBannerColor(state.status),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              _getBannerIcon(state.status),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getBannerTitle(state.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (state.hasError) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: state.isLoading ? null : () => _healthStore.retry(),
                  child: Text(
                    state.isLoading ? 'Retrying...' : 'Retry',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _showDebugDialog(context),
                  icon: const Icon(Icons.bug_report, color: Colors.white, size: 16),
                  tooltip: 'Debug Info',
                ),
              ],
            ],
            if (state.isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBannerColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.loading:
        return Colors.orange;
      case HealthStatus.error:
        return Colors.red;
      case HealthStatus.success:
        return Colors.green;
      case HealthStatus.initial:
        return Colors.grey;
    }
  }

  IconData _getBannerIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.loading:
        return Icons.sync;
      case HealthStatus.error:
        return Icons.warning;
      case HealthStatus.success:
        return Icons.check_circle;
      case HealthStatus.initial:
        return Icons.info;
    }
  }

  String _getBannerTitle(HealthStatus status) {
    switch (status) {
      case HealthStatus.loading:
        return 'Connecting to server...';
      case HealthStatus.error:
        return 'Service connection failed';
      case HealthStatus.success:
        return 'Service connected successfully';
      case HealthStatus.initial:
        return 'Initializing...';
    }
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${_healthStore.state.status}'),
              if (_healthStore.state.errorMessage != null)
                Text('Error: ${_healthStore.state.errorMessage}'),
              if (_healthStore.state.healthInfo != null) ...[
                Text('Service: ${_healthStore.state.healthInfo!.service}'),
                Text('Version: ${_healthStore.state.healthInfo!.version}'),
                Text('Status: ${_healthStore.state.healthInfo!.status}'),
                Text('Healthy: ${_healthStore.state.healthInfo!.isHealthy}'),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
