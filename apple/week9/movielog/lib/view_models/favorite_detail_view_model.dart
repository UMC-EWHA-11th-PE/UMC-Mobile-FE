import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

/// 영화 상세의 즐겨찾기 버튼 상태 (9주차)
///
/// | 상태              | 역할                                   |
/// | ----------------- | -------------------------------------- |
/// | [isLoading]       | 첫 여부 조회 중                        |
/// | [isSaving]        | 등록·해제 중 (버튼 비활성)             |
/// | [isFavorite]      | 서버에서 확인한 값                     |
/// | [hasLoadedStatus] | 여부를 한 번이라도 확인했는지          |
/// | [errorMessage]    | 실패 안내 — 다음 요청을 시작하면 지움  |
///
/// 서버 성공을 확인한 뒤에만 북마크를 바꿉니다. (optimistic update를 쓰지 않음)
///
/// 오류 처리
/// - FAVORITE409_1(이미 등록)·FAVORITE404_1(이미 해제): 같은 요청을 반복하지 않고 여부 GET으로 맞춥니다.
/// - AUTH401_2/3/4: 이 응답이 지금 세션의 것일 때만 세션 만료를 요청합니다. (이전 계정의 늦은 401 무시)
/// - MEMBER404_1(회원 없음)·네트워크 실패: 안내만 하고 이전 아이콘 상태를 유지합니다.
///
/// Route에서 `ValueKey('email:generation')`으로 만들어, 계정·세션이 바뀌면 새로 만듭니다.
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
  });

  /// 상세 화면의 TMDB 영화 ID — 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;

  /// `/members/me`로 확인한 email — 화면 쪽 세션 구분에만 씁니다. (API에는 보내지 않음)
  final String accountId;

  /// 현재 세션에서 세션 만료(AUTH401_2/3/4)를 받았을 때 정리를 요청합니다.
  final Future<void> Function()? onSessionExpired;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  static const saveFailedMessage = '저장하지 못했습니다. 다시 시도해 주세요.';

  /// 요청 시점의 세션 번호와, 지금 요청해도 되는지
  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;
    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  bool _isCurrent(int generation) =>
      sessionGuard.isCurrent(generation, accountId) && !isDisposed;

  /// 첫 여부 조회 — 상세 화면 initState에서 한 번, 실패하면 새로고침 버튼으로 다시 호출합니다.
  Future<void> load() async {
    if (isLoading || isSaving) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!_isCurrent(snap.generation)) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } on DioException catch (error) {
      if (!_isCurrent(snap.generation)) return;
      if (await _handleSessionExpired(error, snap.generation)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } catch (_) {
      if (!_isCurrent(snap.generation)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (_isCurrent(snap.generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  /// 등록·해제 — 서버 성공을 확인한 뒤에 북마크 상태를 바꿉니다. 요청 중에는 중복 탭을 막습니다.
  ///
  /// 상태가 바뀌었으면 바뀐 값(true 등록 / false 해제)을, 아니면 null을 돌려줍니다.
  Future<bool?> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return null;
    final snap = _snapshot();
    if (!snap.ok) return null;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
      }
      if (!_isCurrent(snap.generation)) return null;
      isFavorite = !before;
    } on DioException catch (error) {
      if (!_isCurrent(snap.generation)) return null;
      if (await _handleSessionExpired(error, snap.generation)) return null;
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        // 이미 등록(409)이거나 이미 해제(404)면 같은 요청을 반복하지 않고 서버의 현재 여부로 맞춥니다.
        try {
          final synced = await favoriteApi.checkFavorite(movieId: movieId);
          if (!_isCurrent(snap.generation)) return null;
          isFavorite = synced.isFavorite;
        } catch (_) {
          if (!_isCurrent(snap.generation)) return null;
          isFavorite = before;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else if (code == 'MEMBER404_1') {
        // 즐겨찾기 없음(FAVORITE404_1)과 다른 404 — 회원이 없어 처리되지 않았습니다.
        isFavorite = before;
        errorMessage = '회원 정보를 찾을 수 없습니다. 다시 로그인해 주세요.';
      } else {
        isFavorite = before;
        errorMessage = saveFailedMessage;
      }
    } catch (_) {
      if (!_isCurrent(snap.generation)) return null;
      isFavorite = before;
      errorMessage = saveFailedMessage;
    } finally {
      if (_isCurrent(snap.generation)) {
        isSaving = false;
        notifyIfAlive();
      }
    }
    return isFavorite == before ? null : isFavorite;
  }

  /// 세션 만료 코드면 (지금 세션일 때만) 정리를 요청하고 true를 돌려줍니다.
  /// 403이나 로그인 오류(AUTH401_1)는 세션 만료가 아닙니다.
  Future<bool> _handleSessionExpired(DioException error, int generation) async {
    if (!isSessionExpiredCode(apiErrorCode(error))) return false;
    if (_isCurrent(generation)) await onSessionExpired?.call();
    return true;
  }
}
