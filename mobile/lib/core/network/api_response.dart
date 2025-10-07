/// Unified API Response Model
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final int timestamp;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? 200,
      message: json['message'] as String? ?? 'success',
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : json['data'] as T?,
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  bool get isSuccess => code == 200;
  
  String get errorMessage => isSuccess ? message : 'Error $code: $message';

  /// Parse timestamp from various formats
  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    
    if (timestamp is int) {
      return timestamp;
    }
    
    if (timestamp is String) {
      try {
        // Try to parse as DateTime string
        final dateTime = DateTime.parse(timestamp);
        return dateTime.millisecondsSinceEpoch;
      } catch (e) {
        // If parsing fails, try to parse as milliseconds string
        try {
          return int.parse(timestamp);
        } catch (e2) {
          return DateTime.now().millisecondsSinceEpoch;
        }
      }
    }
    
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// Paged Response Model
class PagedResponse<T> {
  final List<T> items;
  final PaginationInfo pagination;

  const PagedResponse({
    required this.items,
    required this.pagination,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final itemsJson = data['items'] as List? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};

    return PagedResponse<T>(
      items: itemsJson.map((item) => fromJsonT(item)).toList(),
      pagination: PaginationInfo.fromJson(paginationJson),
    );
  }
}

class PaginationInfo {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationInfo({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as int? ?? 1;
    final size = json['size'] as int? ?? 20;
    final total = json['total'] as int? ?? 0;
    final totalPages = json['totalPages'] as int? ?? 0;
    
    return PaginationInfo(
      page: page,
      size: size,
      total: total,
      totalPages: totalPages,
      hasNext: json['hasNext'] as bool? ?? (page < totalPages),
      hasPrev: json['hasPrev'] as bool? ?? (page > 1),
    );
  }
}
