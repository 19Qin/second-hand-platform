import '../../domain/entities/trend_item.dart';
import '../../domain/repositories/trend_repository.dart';
import '../datasources/trend_remote_data_source.dart';

class TrendRepositoryImpl implements TrendRepository {
  final TrendRemoteDataSource ds;
  TrendRepositoryImpl(this.ds);

  @override
  Future<List<TrendEntity>> getTrends({String? keyword}) {
    return ds.getTrends(keyword: keyword);
  }
}
