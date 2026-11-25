/// [items]마다 [task]를 실행하되, 동시에 최대 [concurrency]개만 진행합니다.
///
/// 결과는 `Future.wait`처럼 [items]와 같은 순서로 돌려줍니다.
/// 즐겨찾기가 100개여도 TMDB 상세 요청을 한 번에 5개씩만 보내기 위해 씁니다.
///
/// 하나가 실패하면 전체가 실패하므로, 카드별 실패는 [task] 안에서 결과 값으로 바꿔 돌려줍니다.
Future<List<R>> mapBounded<T, R>(
  List<T> items,
  Future<R> Function(T item) task, {
  int concurrency = 5,
}) async {
  assert(concurrency > 0);
  final results = List<R?>.filled(items.length, null);
  var next = 0;

  // 작업자(worker) 하나는 남은 항목을 하나씩 가져가 끝날 때까지 처리합니다.
  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await task(items[index]);
    }
  }

  final workerCount = items.length < concurrency ? items.length : concurrency;
  await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);
  return [for (final result in results) result as R];
}
