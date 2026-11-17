import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// v7 회원 API 중 로그인 사용자 본인 정보를 다룹니다.
/// 보호 요청이므로 AuthInterceptor가 등록된 보호용 Client를 받습니다.
/// - GET /v7/members/me — 인증 필요, 성공은 200 + `CommonResponse<MemberInfo>`
///
/// 오류(AUTH401_2/3/4, MEMBER404_1 등)는 DioException 그대로 ViewModel로 넘깁니다.
class MemberApiService {
  MemberApiService(this._dio);

  final Dio _dio;

  /// 저장된 JWT가 아직 유효한지 서버에 확인하고 내 정보를 받아옵니다.
  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }
}
