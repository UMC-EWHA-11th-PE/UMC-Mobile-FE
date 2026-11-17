import 'package:dio/dio.dart';

import '../../core/network/auth_token_interceptor.dart';
import '../models/common_response.dart';
import '../models/member_info.dart';

/// v7 회원 API 중 로그인 사용자 본인 정보를 다룹니다.
/// - GET /v7/members/me — 인증 필요, 성공은 200 + `CommonResponse<MemberInfo>`
///
/// 오류(AUTH401_2/3/4, MEMBER404_1 등)는 DioException 그대로 ViewModel로 넘깁니다.
class MemberApiService {
  MemberApiService(this._dio);

  final Dio _dio;

  /// 저장된 JWT가 아직 유효한지 서버에 확인하고 내 정보를 받아옵니다.
  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get('/v7/members/me', options: authOptions());
    final body = CommonResponse<MemberInfo>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
    );
    final member = body.result;
    // 성공 응답인데 result가 없으면 로그인 확정 근거가 없으므로 계약 오류로 봅니다.
    if (member == null) {
      throw const FormatException('내 정보 응답에 result가 없습니다.');
    }
    return member;
  }
}
