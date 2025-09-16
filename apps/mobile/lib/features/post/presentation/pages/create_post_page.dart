import 'package:flutter/material.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Posting')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            _LabeledField(label: 'Title'),
            SizedBox(height: 12),
            _LabeledField(label: 'Price', keyboard: TextInputType.number),
            SizedBox(height: 12),
            _LabeledField(label: 'Description', maxLines: 5),
            SizedBox(height: 24),
            _ImagePickerStub(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              // TODO: submit post
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Submitted (mock)')));
              Navigator.pop(context);
            },
            child: const Text('Post Item'),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextInputType? keyboard;
  final int maxLines;
  const _LabeledField({required this.label, this.keyboard, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      TextField(
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: 'Enter $label',
        ),
      ),
    ]);
  }
}

class _ImagePickerStub extends StatelessWidget {
  const _ImagePickerStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open image picker (mock)')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined),
              SizedBox(width: 8),
              Text('Add Photos'),
            ],
          ),
        ),
      ),
    );
  }
}
