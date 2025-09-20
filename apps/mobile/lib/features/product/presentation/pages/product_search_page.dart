import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/data_sources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/search_products.dart';
import '../widgets/product_list_view.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  late final SearchProducts _search;
  final _controller = TextEditingController();
  Future<ProductListEntity>? _future;

  @override
  void initState() {
    super.initState();
    final ds = ProductRemoteDataSourceImpl(http.Client());
    final repo = ProductRepositoryImpl(ds);
    _search = SearchProducts(repo);
  }

  void _doSearch(String keyword) {
    setState(() {
      _future = _search(keyword: keyword, page: 1, size: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'Search products...'),
          textInputAction: TextInputAction.search,
          onSubmitted: _doSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _doSearch(_controller.text.trim()),
          ),
        ],
      ),
      body: _future == null
          ? const Center(child: Text('Type to search'))
          : FutureBuilder<ProductListEntity>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Failed: ${snap.error}'));
                }
                return ProductListView(items: snap.data!.items);
              },
            ),
    );
  }
}
