import 'package:flutter/material.dart';

/// Пометка «создан локально»: пост есть только на устройстве.
class LocalBadge extends StatelessWidget {
  const LocalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'создан локально',
        style: TextStyle(color: scheme.onTertiary, fontSize: 11),
      ),
    );
  }
}
