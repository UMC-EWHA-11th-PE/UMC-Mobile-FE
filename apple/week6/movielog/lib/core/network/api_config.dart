/// 자체 movie 서버 연결 설정입니다.
///
/// 실행할 때 --dart-define으로 바꿀 수 있습니다.
/// 예) flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080
class ApiConfig {
  ApiConfig._();

  /// Android 에뮬레이터에서는 http://10.0.2.2:8080 으로 바꿔 실행합니다.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// "내가 등록한 평점"의 조회 대상 — 로그인이 아직 없어 학습용 memberId 1로 고정합니다.
  /// 실제 회원 식별은 JWT 주차에서 바뀝니다.
  static const memberId = 1;
}
