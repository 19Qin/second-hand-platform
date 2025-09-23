// change logic

import 'package:flutter/material.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  bool discount = false;
  bool popular = false;
  RangeValues price = const RangeValues(0, 100000);

  void _apply() {
    Navigator.pop(context, {
      'discount': discount,
      'popular': popular,
      'minPrice': price.start.round(),
      'maxPrice': price.end.round(),
    });
  }

  void _clear() {
    setState(() {
      discount = false;
      popular = false;
      price = const RangeValues(0, 100000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(onPressed: _clear, child: const Text('Clear', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: discount,
            onChanged: (v) => setState(() => discount = v),
            title: const Text('Discount only'),
          ),
          SwitchListTile(
            value: popular,
            onChanged: (v) => setState(() => popular = v),
            title: const Text('Popular items'),
          ),
          const SizedBox(height: 12),
          const Text('Price range'),
          RangeSlider(
            values: price,
            min: 0,
            max: 200000,
            divisions: 40,
            labels: RangeLabels('${price.start.round()}', '${price.end.round()}'),
            onChanged: (v) => setState(() => price = v),
            activeColor: cs.primary,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _apply,
            child: const Text('Apply'),
          )
        ],
      ),
    );
  }
}
