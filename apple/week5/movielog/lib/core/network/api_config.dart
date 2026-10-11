import 'package:http/http.dart' as http;

/// 5주차 백엔드(movie 서버) 연결 설정입니다.
///
/// 실행할 때 --dart-define으로 바꿀 수 있습니다.
/// 예) flutter run -d chrome --web-port 5173 --dart-define=MEMBER_ID=2
class ApiConfig {
  ApiConfig._();

  /// Android 에뮬레이터에서는 http://10.0.2.2:8080 으로 바꿔 실행합니다.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// 로그인이 아직 없어 시드 데이터의 회원 ID로 평점을 조회합니다.
  static const memberId = int.fromEnvironment('MEMBER_ID', defaultValue: 1);

  /// 모든 서비스가 함께 쓰는 HTTP 클라이언트 — 테스트에서는 가짜 서버(MockClient)로 바꿉니다.
  static http.Client client = http.Client();

  /// 경로 조각을 이어 붙여 URL을 만듭니다. 한글·특수문자는 자동으로 인코딩됩니다.
  static Uri uri(List<String> pathSegments) {
    final base = Uri.parse(baseUrl);
    return base.replace(pathSegments: [...base.pathSegments, ...pathSegments]);
  }
}
