import 'package:mobile/features/trend/data/datasources/trend_remote_data_source.dart';
import 'package:mobile/features/trend/domain/entities/trend.dart';
import 'package:mobile/features/trend/data/models/trend_model.dart';

class TrendFakeDataSource implements TrendRemoteDataSource {
  @override
  Future<List<TrendEntity>> fetchTopTrends({int limit = 3}) async {
    final list = mockTrends;
    return list.take(limit).toList();
  }
}

/// You can adjust images/types freely.
final List<TrendEntity> mockTrends = <TrendEntity>[
  const TrendModel(
    id: 't1',
    title: 'Flash Sale: PS5 Bundle',
    type: 'Electronics',
    viewCount: 12500,
    likeCount: 820,
    score: 98,
    image: null,
  ),
  const TrendModel(
    id: 't2',
    title: 'Luxury Handbags Weekly Picks',
    type: 'Luxury',
    viewCount: 9800,
    likeCount: 610,
    score: 92,
    image: null,
  ),
  const TrendModel(
    id: 't3',
    title: 'Top Gaming Chairs',
    type: 'Furniture',
    viewCount: 6400,
    likeCount: 410,
    score: 88,
    image: null,
  ),
  const TrendModel(
    id: 't4',
    title: 'Student Laptops Under \$600',
    type: 'Computers',
    viewCount: 7200,
    likeCount: 355,
    score: 86,
    image: null,
  ),
];
