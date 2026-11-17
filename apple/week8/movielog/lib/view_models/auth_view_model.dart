import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/local/secure_storage_cleanup.dart';
import '../data/local/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

/// 앱 전체의 MovieLog 로그인 상태 — GoRouter redirect가 이 값만 보고 화면을 정합니다.
enum AuthStatus {
  /// 저장된 토큰을 읽고 서버에 확인하는 중 → 스플래시(로딩)
  initializing,

  /// 토큰이 없거나 서버가 무효(AUTH401_2/3/4)라고 답함 → 로그인·회원가입만 허용
  signedOut,

  /// 로그인 요청 중 → 로그인 화면 유지
  authenticating,

  /// 로그인 성공(토큰 저장) 또는 `/members/me` 검증 완료 → 보호 화면 허용
  signedIn,

  /// 저장소·네트워크 문제로 확인하지 못함 → 스플래시(다시 시도). 토큰은 지우지 않습니다.
  retryRequired,
}

/// 내 정보(`/members/me`) 불러오기 상태 — 로그인 여부와 따로 관리합니다.
enum MemberLoadStatus { idle, loading, success, error }

/// MovieLog 사용자 세션을 관리합니다.
///
/// - 신규 로그인: 로그인 API 성공 → 토큰 저장 → signedIn → MainScreen이 [loadMember]
/// - 앱 재시작: [restoreSession]이 `/members/me` 검증을 마친 뒤에만 signedIn
/// - 네트워크 실패는 retryRequired(토큰 유지), 토큰 무효 401은 signedOut(토큰 삭제)으로 구별합니다.
/// - [_sessionVersion]으로 이전 세션에서 늦게 도착한 응답이 새 세션을 덮어쓰지 않게 합니다.
/// - 화면 이동은 하지 않습니다. 상태가 바뀌면 Router가 redirect로 화면을 정합니다.
/// - 로그아웃·만료는 MovieLog 세션만 비웁니다. TMDB 설정·영화 목록은 건드리지 않습니다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._authApi,
    this._memberApi,
    this._storage, {
    Future<void> Function()? storageCleanup,
  }) : _installCleanup =
           storageCleanup ?? clearStaleSecureStorageOnFirstInstall;

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  /// 재설치 후 첫 실행이면 Keychain에 남은 이전 설치의 토큰을 지웁니다.
  final Future<void> Function() _installCleanup;

  AuthStatus status = AuthStatus.initializing;

  /// 서버가 확인해 준 내 정보. 신규 로그인 직후에는 [loadMember] 전까지 null
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;

  /// 스플래시 재시도 문구, 로그인 요청 실패, 내 정보 실패 등 화면 전체 안내 문구
  String? message;

  /// 로그인 Form 아래(비밀번호 입력칸)에 보여줄 입력 오류 — AUTH401_1, COMMON400
  String? loginError;

  /// 서버 401로 세션이 정리됐는지 — 사용자가 직접 로그아웃한 경우와 구별합니다.
  bool sessionExpired = false;

  /// 저장된 토큰을 지우는 중 — 이 사이에 로그인·복원을 시작하지 않습니다.
  bool storageCleanupInProgress = false;

  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  bool _disposed = false;
  bool _installCleaned = false;
  bool _installCleanupInProgress = false;

  /// 진행 중인 토큰 저장 — 세션 정리가 저장이 끝난 뒤 삭제하도록 기다립니다.
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 앱 시작 시 한 번 호출합니다. 스플래시의 '다시 시도'도 이 함수를 다시 부릅니다.
  ///
  /// 재설치 정리가 끝나기 전에 토큰을 읽으면 이전 설치의 토큰으로 로그인될 수 있으므로
  /// 정리 → 세션 복원 순서를 지킵니다.
  Future<void> initialize() async {
    if (_installCleanupInProgress || _disposed) return;

    if (!_installCleaned) {
      _installCleanupInProgress = true;
      status = AuthStatus.initializing;
      message = null;
      _notify();
      try {
        await _installCleanup();
        _installCleaned = true;
      } catch (_) {
        status = AuthStatus.retryRequired;
        message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
      } finally {
        _installCleanupInProgress = false;
      }
      if (!_installCleaned) {
        _notify();
        return;
      }
    }

    await restoreSession();
  }

  /// 저장된 토큰을 읽고 `/members/me`로 서버 검증해 로그인 상태를 다시 확정합니다.
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _installCleanupInProgress || _disposed) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();

    final String? token;
    try {
      token = await _storage.readAccessToken();
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
      _notify();
      return;
    }
    if (!_isCurrent(version)) return;

    if (token == null || token.isEmpty) {
      status = AuthStatus.signedOut;
      _notify();
      return;
    }

    memberStatus = MemberLoadStatus.loading;
    try {
      final verifiedMember = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return;
      member = verifiedMember;
      memberStatus = MemberLoadStatus.success;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      final code = apiErrorCode(error);
      // 토큰 없음·무효·만료 — 이 토큰으로는 다시 시도해도 성공할 수 없으므로 세션을 정리합니다.
      if (_isSessionExpiredCode(code)) {
        await _clearCurrentSession();
        return;
      }
      // 토큰은 유효하지만 회원이 없어짐 — 재시도해도 같은 결과이므로 로그인부터 다시 합니다.
      if (code == 'MEMBER404_1') {
        await _clearCurrentSession(expired: false);
        return;
      }
      // 연결 실패·서버 오류 — 유효한 토큰일 수 있으므로 지우지 않고 재시도를 안내합니다.
      memberStatus = MemberLoadStatus.error;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      // 응답 형식이 계약과 다름 — 로그인을 확정할 근거가 없으므로 재시도를 안내합니다.
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  /// 로그인 — 성공하면 토큰을 저장하고 signedIn으로 바꿉니다. 화면 이동은 Router가 합니다.
  ///
  /// 신규 로그인은 여기서 `/members/me`를 다시 부르지 않고, MainScreen의 [loadMember]가 불러옵니다.
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    loginError = null;
    final version = ++_sessionVersion;
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      final code = apiErrorCode(error);
      if (code == 'AUTH401_1') {
        // 로그인 Form 오류 — 세션 만료 처리(전역 401)와 묶지 않습니다.
        loginError = '이메일 또는 비밀번호를 확인해 주세요.';
      } else if (code == 'COMMON400') {
        // 입력값 검증 실패 — 서버 message를 입력칸 아래에 그대로 보여줍니다.
        loginError = apiErrorMessage(error) ?? '입력값을 다시 확인해 주세요.';
      } else {
        message = '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
      }
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  /// 입력값이 바뀌면 이전 로그인 실패 문구는 더 이상 그 값에 대한 것이 아니므로 지웁니다.
  void clearLoginError() {
    if (loginError == null) return;
    loginError = null;
    _notify();
  }

  /// 내 정보를 불러와 [member]에 보관합니다. MainScreen이 처음 열릴 때 한 번 호출합니다.
  ///
  /// 앱 재시작은 [restoreSession]이 이미 채웠으므로 [force] 없이는 다시 부르지 않습니다.
  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (_isSessionExpiredCode(apiErrorCode(error))) {
        // 세션 만료: signedOut이 되어 Router가 /login으로 보냅니다.
        await _clearCurrentSession();
        return;
      }
      // 네트워크 실패: 로그아웃하지 않고 재시도할 수 있게 남깁니다.
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 메모리의 내 정보를 교체합니다. GET me를 다시 호출하지 않습니다.
  /// 마이페이지가 [member]를 구독하고 있어 화면 이동 없이 새 닉네임이 보입니다.
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    _notify();
  }

  /// 다른 ViewModel이 보호 요청에서 401(AUTH401_2/3/4)을 받았을 때 세션 정리를 요청하는 공개 진입점입니다.
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  /// 사용자가 직접 누르는 로그아웃 — 만료 안내 없이 세션만 비웁니다.
  /// MovieLog 세션만 정리하고 TMDB 설정·영화 목록은 건드리지 않습니다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  static bool _isSessionExpiredCode(String? code) =>
      code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';

  /// 토큰 만료·무효([expired] true) 또는 로그아웃으로 현재 세션을 비웁니다.
  ///
  /// 세션 버전 증가 → signedOut → 저장된 토큰 삭제. 화면 이동은 Router가 /login으로 합니다.
  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    loginError = null;
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제합니다. 정리 중 새 로그인은 막습니다.
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장 실패여도 삭제는 시도합니다.
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
