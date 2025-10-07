import 'package:flutter/material.dart';

/// Error State Component
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const ErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    this.message,
    this.actionText = 'Retry',
    this.onAction,
  });

  /// Network Error
  const ErrorState.network({
    super.key,
    this.title = 'Network connection failed',
    this.message = 'Please check your network connection and try again',
    this.actionText = 'Retry',
    this.onAction,
  }) : icon = Icons.wifi_off;

  /// Server Error
  const ErrorState.server({
    super.key,
    this.title = 'Service temporarily unavailable',
    this.message = 'Server encountered an issue, please try again later',
    this.actionText = 'Retry',
    this.onAction,
  }) : icon = Icons.cloud_off;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.error.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
