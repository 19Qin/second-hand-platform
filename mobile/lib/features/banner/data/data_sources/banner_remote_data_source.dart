import '../../../../core/network/api_client.dart';
import '../models/banner_model.dart';

abstract class BannerRemoteDataSource {
  Future<List<BannerModel>> fetchBanners({
    String type = 'homepage',
    String status = 'active',
  });
}

class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final ApiClient _apiClient;

  BannerRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<BannerModel>> fetchBanners({
    String type = 'homepage',
    String status = 'active',
  }) async {
    final queryParameters = <String, String>{
      'type': type,
      'status': status,
    };

    final response = await _apiClient.get<List<BannerModel>>(
      'banners',
      queryParameters: queryParameters,
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return <BannerModel>[];
      },
    );
    
    return response;
  }
}
