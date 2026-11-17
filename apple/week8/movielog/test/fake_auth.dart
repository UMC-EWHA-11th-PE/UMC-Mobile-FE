import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movielog/data/local/auth_token_storage.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

/// 보안 저장소 대신 메모리에 토큰을 두는 저장소 — 플랫폼 채널 없이 테스트합니다.
class InMemoryTokenStorage extends AuthTokenStorage {
  InMemoryTokenStorage([this.token]);

  String? token;

  /// true면 읽기에서 예외 — 저장소 오류 확인용
  bool failRead = false;
  int deleteCount = 0;

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw Exception('keychain unavailable');
    return token;
  }

  @override
  Future<void> writeAccessToken(String token) async => this.token = token;

  @override
  Future<void> deleteAccessToken() async {
    deleteCount++;
    token = null;
  }
}

final fakeMember = MemberInfo(
  email: 'mingo@example.com',
  nickname: '밍고',
  createdAt: DateTime.utc(2026, 9, 6),
);

/// `/v7/members/me`를 흉내 냅니다.
/// - 기본은 [member] 응답
/// - [errorCode]가 있으면 [errorStatus]와 공통 오류 body로 실패
/// - [connectionError]가 true면 응답 없는 연결 실패
/// - [gate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — 늦은 응답 확인용
class FakeMemberApiService extends MemberApiService {
  FakeMemberApiService({
    MemberInfo? member,
    this.errorCode,
    this.errorStatus = 401,
    this.connectionError = false,
    this.gate,
  }) : member = member ?? fakeMember,
       super(Dio());

  MemberInfo member;
  String? errorCode;
  int errorStatus;
  bool connectionError;
  Future<void>? gate;
  int calls = 0;

  @override
  Future<MemberInfo> fetchMe() async {
    calls++;
    final options = RequestOptions(path: '/v7/members/me');
    if (gate != null) await gate;
    if (connectionError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final code = errorCode;
    if (code != null) {
      throw DioException.badResponse(
        statusCode: errorStatus,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: errorStatus,
          data: {
            'isSuccess': false,
            'code': code,
            'message': 'error',
            'result': null,
          },
        ),
      );
    }
    return member;
  }
}

/// 저장소 정리를 건너뛰는 AuthViewModel — 플랫폼 채널 없이 테스트합니다.
AuthViewModel fakeAuth({
  String? token = 'test-token',
  FakeMemberApiService? memberApi,
  InMemoryTokenStorage? storage,
}) {
  return AuthViewModel(
    storage ?? InMemoryTokenStorage(token),
    memberApi ?? FakeMemberApiService(),
    storageCleanup: () async {},
  );
}

/// `/members/me` 검증까지 끝난 로그인 세션 — 보호 화면 테스트의 기본값입니다.
Future<AuthViewModel> signedInAuth() async {
  final auth = fakeAuth();
  await auth.initialize();
  return auth;
}

/// 토큰이 없는 로그아웃 세션
Future<AuthViewModel> signedOutAuth() async {
  final auth = fakeAuth(token: null);
  await auth.initialize();
  return auth;
}

/// 앱(MovieLogApp)이 만든 GoRouter — 테스트마다 새로 만들어집니다.
GoRouter appRouter(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig
        as GoRouter;
