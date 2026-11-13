/// Результат замера одного запроса с индексами и без них.
class BenchmarkResult {
  const BenchmarkResult({
    required this.query,
    required this.withIndexMs,
    required this.withoutIndexMs,
  });

  final String query;

  /// Среднее время одного выполнения, мс.
  final double withIndexMs;
  final double withoutIndexMs;

  double get speedup => withIndexMs == 0 ? 0 : withoutIndexMs / withIndexMs;
}
