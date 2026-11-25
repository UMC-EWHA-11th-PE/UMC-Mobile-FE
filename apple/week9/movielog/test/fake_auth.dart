import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movielog/data/local/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

/// 보안 저장소 대신 메모리에 토큰을 두는 저장소 — 플랫폼 채널 없이 테스트합니다.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.token]);

  String? token;

  /// true면 읽기에서 예외 — 저장소 오류 확인용
  bool failRead = false;

  /// true면 저장에서 예외 — 로그인 후 토큰 저장 실패 확인용
  bool failSave = false;

  /// true면 삭제에서 예외 — 로그아웃·만료 때 토큰 삭제 실패 확인용
  bool failDelete = false;
  int deleteCount = 0;

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw Exception('keychain unavailable');
    return token;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    if (failSave) throw Exception('keychain unavailable');
    this.token = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    deleteCount++;
    if (failDelete) throw Exception('keychain unavailable');
    token = null;
  }
}

final fakeMember = MemberInfo(
  email: 'mingo@example.com',
  nickname: '밍고',
  createdAt: DateTime.utc(2026, 9, 6),
);

/// 공통 오류 body를 담은 DioException
DioException fakeApiError(String path, String code, int status) {
  final options = RequestOptions(path: path);
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'isSuccess': false,
        'code': code,
        'message': 'server message for $code',
        'result': null,
      },
    ),
  );
}

DioException _connectionError(String path) => DioException(
  requestOptions: RequestOptions(path: path),
  type: DioExceptionType.connectionError,
);

/// `/v8/members/me`를 흉내 냅니다.
/// - 기본은 [member] 응답
/// - [errorCode]가 있으면 [errorStatus]와 공통 오류 body로 실패
/// - [connectionError]가 true면 응답 없는 연결 실패
/// - [gate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — 늦은 응답 확인용
///
/// 닉네임 수정 (PATCH /v8/members/me)
/// - 기본은 같은 email에 바뀐 닉네임으로 응답, [nicknameRequests]에 기록
/// - [updateErrorCode]·[updateErrorStatus]·[updateConnectionError]·[updateGate]로 실패·지연
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

  String? updateErrorCode;
  int updateErrorStatus = 409;
  bool updateConnectionError = false;
  Future<void>? updateGate;
  final nicknameRequests = <String>[];

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    nicknameRequests.add(nickname);
    if (updateGate != null) await updateGate;
    if (updateConnectionError) throw _connectionError('/v8/members/me');
    final code = updateErrorCode;
    if (code != null) {
      throw fakeApiError('/v8/members/me', code, updateErrorStatus);
    }
    member = MemberInfo(
      email: member.email,
      nickname: nickname,
      createdAt: member.createdAt,
    );
    return member;
  }

  @override
  Future<MemberInfo> fetchMe() async {
    calls++;
    if (gate != null) await gate;
    if (connectionError) throw _connectionError('/v8/members/me');
    final code = errorCode;
    if (code != null) throw fakeApiError('/v8/members/me', code, errorStatus);
    return member;
  }
}

/// `POST /v8/auth/login`을 흉내 냅니다.
/// - 기본은 nickname 밍고 + [accessToken] 응답
/// - [errorCode]가 있으면 [errorStatus]와 공통 오류 body로 실패
/// - [connectionError]가 true면 응답 없는 연결 실패
/// - [gate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — 요청 중 상태 확인용
/// - [requests]에 보낸 요청을 기록
class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService({
    this.accessToken = 'new-token',
    this.errorCode,
    this.errorStatus = 401,
    this.connectionError = false,
    this.gate,
  }) : super(Dio());

  String accessToken;
  String? errorCode;
  int errorStatus;
  bool connectionError;
  Future<void>? gate;
  final requests = <LoginRequest>[];

  @override
  Future<LoginResult> login(LoginRequest request) async {
    requests.add(request);
    if (gate != null) await gate;
    if (connectionError) throw _connectionError('/v8/auth/login');
    final code = errorCode;
    if (code != null) throw fakeApiError('/v8/auth/login', code, errorStatus);
    return LoginResult(nickname: '밍고', accessToken: accessToken);
  }
}

/// 저장소 정리를 건너뛰는 AuthViewModel — 플랫폼 채널 없이 테스트합니다.
AuthViewModel fakeAuth({
  String? token = 'test-token',
  FakeAuthApiService? authApi,
  FakeMemberApiService? memberApi,
  InMemoryTokenStorage? storage,
}) {
  return AuthViewModel(
    authApi ?? FakeAuthApiService(),
    memberApi ?? FakeMemberApiService(),
    storage ?? InMemoryTokenStorage(token),
    storageCleanup: () async {},
  );
}

/// `/members/me` 검증까지 끝난 로그인 세션 — 보호 화면 테스트의 기본값입니다.
Future<AuthViewModel> signedInAuth({
  FakeMemberApiService? memberApi,
  InMemoryTokenStorage? storage,
}) async {
  final auth = fakeAuth(memberApi: memberApi, storage: storage);
  await auth.initialize();
  return auth;
}

/// 토큰이 없는 로그아웃 세션
Future<AuthViewModel> signedOutAuth({FakeAuthApiService? authApi}) async {
  final auth = fakeAuth(token: null, authApi: authApi);
  await auth.initialize();
  return auth;
}

/// 앱(MovieLogApp)이 만든 GoRouter — 테스트마다 새로 만들어집니다.
GoRouter appRouter(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig
        as GoRouter;
