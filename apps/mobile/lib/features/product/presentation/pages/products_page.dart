import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';
import '../widgets/product_list_view.dart';

class ProductsPage extends StatefulWidget {
  final int? categoryId;
  const ProductsPage({super.key, this.categoryId});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final GetProducts _getProducts;
  Future<ProductListEntity>? _future;

  @override
  void initState() {
    super.initState();
    final ds = ProductRemoteDataSourceImpl(http.Client());
    final repo = ProductRepositoryImpl(ds);
    _getProducts = GetProducts(repo);
    _future = _getProducts(
      page: 1,
      size: 20,
      categoryId: widget.categoryId,
      sort: 'created_at_desc',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: FutureBuilder<ProductListEntity>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed: ${snap.error}'));
          }
          final data = snap.data!;
          return ProductListView(items: data.items);
        },
      ),
    );
  }
}
