import '../entities/banner.dart';
import '../repositories/banner_repository.dart';

class GetBanners {
  final BannerRepository repository;

  GetBanners(this.repository);

  Future<List<BannerEntity>> call() {
    return repository.getBanners();
  }
}
