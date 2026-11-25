import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/login_models.dart';

/// 공개 Client(토큰 없음)를 사용하는 인증 Service입니다.
class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  static const signUpPath = '/v8/members';

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

  /// 성공(201)이면 정상 종료, 실패면 DioException을 그대로 던집니다.
  Future<void> signUp(CreateMemberRequest request) async {
    await _dio.post(signUpPath, data: request.toJson());
  }
}
