import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner_model.dart';

abstract class BannerRemoteDataSource {
  Future<List<BannerModel>> fetchBanners();
}

class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final http.Client client;

  BannerRemoteDataSourceImpl(this.client);

  @override
  Future<List<BannerModel>> fetchBanners() async {
    final response = await client
        .get(Uri.parse('https://api.fliliy.com/banners?type=homepage&status=active'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((e) => BannerModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load banners");
    }
  }
}
