import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/login_models.dart';

/// v8 로그인 API(v7과 계약 동일)를 호출합니다. 공개 요청이므로 Interceptor 없는 공개 Client를 받습니다.
/// - POST /v8/auth/login — 성공은 200 + `CommonResponse<LoginResult>`
///
/// 실패(AUTH401_1 이메일·비밀번호 불일치, COMMON400 입력값)는 DioException 그대로 넘깁니다.
class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post('/v8/auth/login', data: request.toJson());
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('로그인 응답 형식이 올바르지 않습니다.');
    }
    final common = CommonResponse<LoginResult>.fromJson(
      data,
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    );
    final result = common.result;
    if (result == null) throw StateError('로그인 result가 없습니다.');
    return result;
  }
}
