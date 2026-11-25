/// [values]마다 [convert]를 실행하되, 동시에 최대 [concurrency]개만 진행합니다.
///
/// 결과는 `Future.wait`처럼 [values]와 같은 순서로 돌려줍니다.
/// 즐겨찾기가 100개여도 TMDB 상세 요청을 한 번에 5개씩만 보내기 위해 씁니다.
///
/// 하나가 실패하면 전체가 실패하므로, 카드별 실패는 [convert] 안에서 결과 값으로 바꿔 돌려줍니다.
Future<List<R>> mapBounded<T, R>(
  Iterable<T> values,
  int concurrency,
  Future<R> Function(T value) convert,
) async {
  final input = values.toList(growable: false);
  if (input.isEmpty) return <R>[];
  if (concurrency <= 0) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be positive');
  }
  final output = List<R?>.filled(input.length, null);
  var next = 0;

  // 작업자(worker) 하나는 남은 항목을 하나씩 가져가 끝날 때까지 처리합니다.
  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= input.length) return;
      output[index] = await convert(input[index]);
    }
  }

  final workers = List.generate(
    concurrency.clamp(1, input.length),
    (_) => worker(),
  );
  await Future.wait(workers);
  return [for (final value in output) value as R];
}
