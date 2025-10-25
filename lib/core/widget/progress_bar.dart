// lib/core/widgets/progress_bar.dart
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  const ProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        backgroundColor: cs.surfaceContainerHighest,
        color: cs.primary,
        minHeight: 8,
      ),
    );
  }
}
