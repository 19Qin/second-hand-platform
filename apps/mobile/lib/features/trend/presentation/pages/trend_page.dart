import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/trend.dart';
import '../../domain/usecases/get_top_trends.dart';
import '../../data/datasources/trend_remote_data_source.dart';
import '../../data/repository/trend_repository_impl.dart';
import '../widgets/trend_panel.dart';

class TrendPage extends StatefulWidget {
  const TrendPage({super.key});
  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  late final GetTopTrends _getTopTrends;
  late Future<List<TrendItemEntity>> _future;

  @override
  void initState() {
    super.initState();
    final ds = TrendRemoteDataSourceImpl(http.Client());
    final repo = TrendRepositoryImpl(ds);
    _getTopTrends = GetTopTrends(repo);
    _future = _getTopTrends(limit: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trend')),
      body: FutureBuilder<List<TrendItemEntity>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed: ${snap.error}'));
          }
          final items = snap.data ?? const <TrendItemEntity>[];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TrendPanel(
                items: items,
                onTap: (e) {
                  // TODO: push product detail by e.id
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open product ${e.id}')),
                  );
                },
                onMore: () {
                  // TODO: go to more trends page
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
