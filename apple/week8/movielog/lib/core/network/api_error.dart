import 'package:dio/dio.dart';

/// MovieLog 오류 응답 `{ isSuccess, code, message, result }`에서 값을 꺼내는 공통 함수입니다.
///
/// body가 공통 형식이 아니면(연결 실패, HTML 오류 페이지 등) null을 돌려줍니다.
///
/// - code: 다음 UI 행동을 정할 때 씁니다.
///   예) AUTH401_1은 로그인 Form 오류, AUTH401_2/3/4만 세션 만료 처리 후보,
///   RATING403_1은 안내만 하고 로그아웃하지 않음
/// - message: 사용자에게 그대로 보여줄 수 있는 서버 안내 문구
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청의 세션 만료 후보(토큰 없음·무효·만료)인지 — 현재 세션을 정리합니다.
///
/// 로그인 Form 오류인 AUTH401_1은 포함하지 않습니다.
bool isSessionExpiredCode(String? code) =>
    code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
