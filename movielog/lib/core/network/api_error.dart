import 'package:dio/dio.dart';

/// 서버 오류 응답 body의 code를 꺼냅니다. (예: AUTH401_2, RATING409_1)
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 서버 오류 응답 body의 message를 꺼냅니다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없거나(2) 무효하거나(3) 만료된(4) 경우입니다.
/// 로그인 실패(AUTH401_1)는 여기에 포함하지 않습니다.
bool isSessionExpiredError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}

/// ViewModel이 Dialog·화면에 "보여줄 문구"를 담아 던지는 예외입니다.
class UserMessageException implements Exception {
  const UserMessageException(this.message);
  final String message;

  @override
  String toString() => message;
}
