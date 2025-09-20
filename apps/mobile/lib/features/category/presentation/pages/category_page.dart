import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../data/data_sources/category_remote_data_source.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories.dart';
import '../widgets/category_nav.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final GetCategories _getCategories;
  late Future<List<CategoryEntity>> _future;

  @override
  void initState() {
    super.initState();
    final ds = CategoryRemoteDataSourceImpl(http.Client());
    final repo = CategoryRepositoryImpl(ds);
    _getCategories = GetCategories(repo);
    _future = _getCategories(
      parentId: 0,
      isActive: true,
      includeChildren: true,
    );
  }

  void _onCategorySelected(int categoryId) {
    // TODO: navigate to your product list page & filter by categoryId
    // e.g. context.push('/products?category=$categoryId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected category: $categoryId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<CategoryEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load categories: ${snapshot.error}'),
            );
          }
          final categories = snapshot.data ?? const <CategoryEntity>[];
          return CategoryNav(
            categories: categories,
            onCategorySelected: _onCategorySelected,
          );
        },
      ),
    );
  }
}
