import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/local/auth_token_storage.dart';
import '../data/local/secure_storage_cleanup.dart';
import '../data/models/member_info.dart';
import '../data/services/member_api_service.dart';

/// 앱 전체의 MovieLog 로그인 상태 — GoRouter redirect가 이 값만 보고 화면을 정합니다.
enum AuthStatus {
  /// 저장된 토큰을 읽고 서버에 확인하는 중 → 스플래시(로딩)
  initializing,

  /// 저장소·네트워크 문제로 확인하지 못함 → 스플래시(다시 시도). 토큰은 지우지 않습니다.
  retryRequired,

  /// 토큰이 없거나 서버가 무효(AUTH401_2/3/4)라고 답함 → 로그인·회원가입만 허용
  signedOut,

  /// 로그인 요청 중 → 로그인 화면 유지
  authenticating,

  /// `/members/me` 서버 검증까지 끝남 → 보호 화면 허용
  signedIn,
}

/// 내 정보(`/members/me`) 불러오기 상태 — 로그인 여부와 따로 관리합니다.
enum MemberLoadStatus { idle, loading, success, failure }

/// MovieLog 사용자 세션을 관리합니다.
///
/// - 토큰 문자열이 있다는 이유만으로 signedIn을 확정하지 않고, `/members/me`로 검증합니다.
/// - 네트워크 실패는 retryRequired(토큰 유지), 토큰 무효 401은 signedOut(토큰 삭제)으로 구별합니다.
/// - [_sessionVersion]으로 이전 세션에서 늦게 도착한 응답이 새 세션을 덮어쓰지 않게 합니다.
/// - 로그아웃은 MovieLog 세션만 비웁니다. TMDB 설정·영화 목록은 건드리지 않습니다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._storage,
    this._memberApi, {
    Future<void> Function()? storageCleanup,
  }) : _storageCleanup =
           storageCleanup ?? clearStaleSecureStorageOnFirstInstall;

  final AuthTokenStorage _storage;
  final MemberApiService _memberApi;

  /// 재설치 후 첫 실행이면 Keychain에 남은 이전 설치의 토큰을 지웁니다.
  final Future<void> Function() _storageCleanup;

  AuthStatus status = AuthStatus.initializing;

  /// 스플래시·로그인 화면에 보여줄 안내 문구 (확인 실패, 로그인 만료 등)
  String? message;

  /// 서버가 확인해 준 내 정보. signedIn이 아니면 null
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;

  int _sessionVersion = 0;
  bool _disposed = false;
  bool _storageCleaned = false;
  bool _storageCleanupInProgress = false;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 앱 시작 시 한 번 호출합니다. 스플래시의 '다시 시도'도 이 함수를 다시 부릅니다.
  ///
  /// 저장소 정리(재설치 확인)가 끝나기 전에 토큰을 읽으면 이전 설치의 토큰으로
  /// 로그인될 수 있으므로, 정리 → 세션 복원 순서를 지킵니다.
  Future<void> initialize() async {
    if (_storageCleanupInProgress || _disposed) return;

    if (!_storageCleaned) {
      _storageCleanupInProgress = true;
      status = AuthStatus.initializing;
      message = null;
      _notify();
      try {
        await _storageCleanup();
        _storageCleaned = true;
      } catch (_) {
        status = AuthStatus.retryRequired;
        message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
      } finally {
        _storageCleanupInProgress = false;
      }
      if (!_storageCleaned) {
        _notify();
        return;
      }
    }

    await restoreSession();
  }

  /// 저장된 토큰을 읽고 `/members/me`로 서버 검증해 로그인 상태를 다시 확정합니다.
  Future<void> restoreSession() async {
    if (_storageCleanupInProgress || _disposed) return;
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
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 토큰은 유효하지만 회원이 없어짐 — 재시도해도 같은 결과이므로 로그인부터 다시 합니다.
      if (code == 'MEMBER404_1') {
        await _clearCurrentSession(message: '회원 정보를 찾을 수 없어요. 다시 로그인해 주세요.');
        return;
      }
      // 연결 실패·서버 오류 — 유효한 토큰일 수 있으므로 지우지 않고 재시도를 안내합니다.
      memberStatus = MemberLoadStatus.failure;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      // 응답 형식이 계약과 다름 — 로그인을 확정할 근거가 없으므로 재시도를 안내합니다.
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.failure;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  /// 현재 세션의 토큰과 메모리 상태를 비우고 signedOut으로 바꿉니다.
  ///
  /// 버전을 올려, 정리 전에 출발한 요청의 응답이 늦게 와도 상태를 되살리지 못하게 합니다.
  Future<void> _clearCurrentSession({
    bool expired = false,
    String? message,
  }) async {
    final version = ++_sessionVersion;
    try {
      await _storage.deleteAccessToken();
    } catch (_) {
      // 삭제에 실패해도 메모리 세션은 비웁니다. 다음 실행 때 서버가 다시 401로 판단합니다.
    }
    if (!_isCurrent(version)) return;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    status = AuthStatus.signedOut;
    this.message = message ?? (expired ? '로그인이 만료되었어요. 다시 로그인해 주세요.' : null);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
