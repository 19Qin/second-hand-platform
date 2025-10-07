import '../entities/trend.dart';

abstract class TrendRepository {
  Future<List<TrendEntity>> getTrends({String? keyword});
}
