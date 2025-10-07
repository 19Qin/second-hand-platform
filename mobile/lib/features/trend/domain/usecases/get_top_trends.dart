import '../entities/trend_item.dart';
import '../repositories/trend_repository.dart';

class GetTrends {
  final TrendRepository repo;
  const GetTrends(this.repo);

  Future<List<TrendEntity>> call({String? keyword}) {
    return repo.getTrends(keyword: keyword);
  }
}
