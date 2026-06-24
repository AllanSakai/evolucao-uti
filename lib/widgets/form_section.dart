import 'package:flutter/material.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: item,
                )),
          ],
        ),
      ),
    );
  }
}
