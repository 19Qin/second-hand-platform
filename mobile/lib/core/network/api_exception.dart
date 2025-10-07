/// Custom API Exception
class ApiException implements Exception {
  final int code;
  final String message;
  final String? details;

  const ApiException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException($code): $message${details != null ? ' - $details' : ''}';
}

/// Network Exception
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.details,
  }) : super(code: -1);
}

/// Server Exception
class ServerException extends ApiException {
  const ServerException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// Parse Exception
class ParseException extends ApiException {
  const ParseException({
    required super.message,
    super.details,
  }) : super(code: -2);
}
