import '../models/user_product_model.dart';
import '../../../../core/network/api_client.dart';

abstract class UserProductsRemoteDataSource {
  Future<UserProductsResponseModel> getUserProducts({
    String? status,
    int page = 1,
    int size = 10,
    String sort = 'time_desc',
  });
}

class UserProductsRemoteDataSourceImpl implements UserProductsRemoteDataSource {
  final ApiClient _apiClient;

  UserProductsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProductsResponseModel> getUserProducts({
    String? status,
    int page = 1,
    int size = 10,
    String sort = 'time_desc',
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };
    
    // Only add status parameter if it's not null
    if (status != null) {
      queryParameters['status'] = status;
    }

    return await _apiClient.get<UserProductsResponseModel>(
      '/user/products',
      queryParameters: queryParameters,
      fromJson: (json) {
        // ApiClient has already extracted the data field, json is the content of data
        // The API returns data in 'content' field, not 'products'
        return UserProductsResponseModel.fromJson({
          'products': json['content'] ?? [],
          'summary': {
            'total': json['pagination']?['total'] ?? 0,
            'active': 0, // Will be calculated from actual data
            'sold': 0,   // Will be calculated from actual data
            'inactive': 0, // Will be calculated from actual data
          },
          'pagination': json['pagination'] ?? {},
        });
      },
    );
  }
}




