import '../../domain/entities/banner.dart';
import '../../domain/repositories/banner_repository.dart';
import '../data_sources/banner_remote_data_source.dart';

class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;

  BannerRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<BannerEntity>> getBanners() async {
    final models = await remoteDataSource.fetchBanners();
    return models; // already extends BannerEntity
  }
}
