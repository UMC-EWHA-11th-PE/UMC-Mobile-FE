/// v5 닉네임·이메일 중복 체크 API의 응답입니다. 예) { "available": true }
///
/// v5는 공통 Wrapper가 없어 응답 body를 그대로 [CheckResult.fromJson]에 넘깁니다.
/// 6주차 이후 API의 `result` Wrapper 파싱과 헷갈리지 않도록 구분합니다.
class CheckResult {
  const CheckResult({required this.available});

  /// 사용할 수 있는 값이면 true, 이미 사용 중이면 false
  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
