import 'package:flutter/material.dart';

/// Состояние Error: понятное сообщение и кнопка повтора.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Состояние Empty: нет постов или поиск ничего не нашёл.
class EmptyView extends StatelessWidget {
  final String message;
  final VoidCallback? onReset;

  const EmptyView({super.key, required this.message, this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onReset != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onReset,
                child: const Text('Сбросить фильтры'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Состояние Cached: показывает, что на экране сохранённые данные.
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = savedAt == null
        ? ''
        : ' от ${savedAt!.day.toString().padLeft(2, '0')}.'
            '${savedAt!.month.toString().padLeft(2, '0')} '
            '${savedAt!.hour.toString().padLeft(2, '0')}:'
            '${savedAt!.minute.toString().padLeft(2, '0')}';
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
                child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
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
