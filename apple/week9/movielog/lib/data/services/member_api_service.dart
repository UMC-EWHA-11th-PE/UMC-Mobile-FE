import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// v8 회원 API(v7과 계약 동일) 중 로그인 사용자 본인 정보를 다룹니다.
/// 보호 요청이므로 AuthInterceptor가 등록된 보호용 Client를 받습니다.
/// - GET   /v8/members/me — 인증 필요, 성공은 200 + `CommonResponse<MemberInfo>`
/// - PATCH /v8/members/me — 인증 필요, 닉네임만 수정. 성공 result는 수정된 내 정보
///
/// 오류(AUTH401_2/3/4, MEMBER404_1, MEMBER409_1, COMMON400 등)는
/// DioException 그대로 ViewModel로 넘깁니다.
class MemberApiService {
  MemberApiService(this._dio);

  final Dio _dio;

  /// 저장된 JWT가 아직 유효한지 서버에 확인하고 내 정보를 받아옵니다.
  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get('/v8/members/me');
    return parseMemberInfo(response.data);
  }

  /// 닉네임 수정 — 응답이 이미 최신 내 정보이므로 GET me를 다시 부르지 않아도 됩니다.
  /// 닉네임 중복은 회원가입의 COMMON409와 달리 MEMBER409_1입니다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _dio.patch(
      '/v8/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
