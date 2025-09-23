import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/trend_model.dart';
import '../../domain/entities/trend.dart';

abstract class TrendRemoteDataSource {
  /// Return entities so upper layers don’t depend on data models
  Future<List<TrendEntity>> fetchTopTrends({int limit = 3});
}

class TrendRemoteDataSourceImpl implements TrendRemoteDataSource {
  static const _apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'https://api.fliliy.com');

  final http.Client client;
  TrendRemoteDataSourceImpl(this.client);

  @override
  Future<List<TrendEntity>> fetchTopTrends({int limit = 3}) async {
    final uri = Uri.parse('$_apiBase/trends/top').replace(queryParameters: {
      'limit': limit.toString(),
    });

    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('GET /trends/top failed (${res.statusCode})');
    }

    final root = json.decode(res.body) as Map<String, dynamic>;
    final list = (root['data'] as List?) ?? const <dynamic>[];

    // Parse into models
    final models = list
        .map((e) => TrendModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Ensure 1..N order if rank exists; otherwise keep API order
    models.sort((a, b) => ((a.rank ?? 1 << 30)).compareTo(b.rank ?? 1 << 30));

    // Return as entities (safe copy to avoid variance issues)
    return List<TrendEntity>.from(models);
  }
}
