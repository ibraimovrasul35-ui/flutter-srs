import 'package:flutter/material.dart';

/// Полоса над списком: показаны сохранённые данные и/или ошибка обновления.
class CacheBanner extends StatelessWidget {
  final DateTime? savedAt;
  final String? error;
  final bool isUpdating;

  const CacheBanner({
    super.key,
    this.savedAt,
    this.error,
    this.isUpdating = false,
  });

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final at = savedAt;
    final time = at == null
        ? ''
        : ' от ${_two(at.day)}.${_two(at.month)} ${_two(at.hour)}:${_two(at.minute)}';
    final text = error != null
        ? '$error. Показаны сохранённые данные$time'
        : isUpdating
            ? 'Показаны сохранённые данные$time, обновляем…'
            : 'Показаны сохранённые данные$time';

    return Material(
      color: error != null ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(error != null ? Icons.wifi_off : Icons.history, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
            if (isUpdating && error == null)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
