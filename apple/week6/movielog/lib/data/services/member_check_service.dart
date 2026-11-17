import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// v5 닉네임·이메일 중복 체크 API를 호출합니다.
/// - GET /v5/members/nickname/{nickname}
/// - GET /v5/members/email/{email}
///
/// HTTP 요청과 응답 변환만 담당하고, 통신 실패(DioException)는 그대로 ViewModel로 넘깁니다.
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  /// 사용할 수 있는 닉네임이면 true
  Future<bool> checkNickname(String nickname) async {
    // 한글·특수문자가 경로를 깨뜨리지 않도록 인코딩합니다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 사용할 수 있는 이메일이면 true
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
