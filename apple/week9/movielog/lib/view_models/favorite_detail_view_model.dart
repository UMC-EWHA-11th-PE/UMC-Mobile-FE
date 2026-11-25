import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

/// 영화 상세의 즐겨찾기 버튼 상태 — 이 영화가 현재 사용자의 즐겨찾기인지 (9주차)
///
/// - 처음 진입: GET /v8/favorites/{movieId}로 현재 여부를 확인합니다.
/// - 버튼: 등록이면 POST, 해제면 DELETE. 요청 중에는 버튼을 로딩으로 바꾸고 다시 누를 수 없습니다.
/// - 낙관적 갱신을 하지 않습니다. 서버가 성공을 돌려준 뒤에만 버튼 모양을 바꿉니다.
///
/// 오류 처리
/// - FAVORITE409_1(이미 등록)·FAVORITE404_1(이미 해제): 같은 요청을 반복하지 않고 GET으로 현재 여부를 맞춥니다.
/// - AUTH401_2/3/4: 이 응답이 지금 세션의 것일 때만 세션 만료를 요청합니다. (이전 계정의 늦은 401 무시)
/// - MEMBER404_1(회원 없음)·네트워크·저장소 실패: 안내만 하고 이전 버튼 상태를 유지합니다.
///
/// 계정별 상태라 Route에서 `ValueKey('email:generation')`으로 만들어, 계정이 바뀌면 새로 만듭니다.
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel(
    this._api, {
    required this.movieId,
    required SessionGuard guard,
    this.onSessionExpired,
  }) : _guard = guard,
       _generation = guard.generation,
       _accountId = guard.accountId;

  final FavoriteApiService _api;
  final SessionGuard _guard;

  /// TMDB 영화 id — 여부 조회·해제 경로에 그대로 넣습니다. (favoriteId가 아님)
  final int? movieId;

  /// 현재 세션에서 세션 만료(AUTH401_2/3/4)를 받았을 때 정리를 요청합니다.
  final Future<void> Function()? onSessionExpired;

  /// 이 ViewModel을 만든 세션 — 응답이 도착했을 때 지금 세션과 같은지 비교합니다.
  final int _generation;
  final String? _accountId;

  /// null이면 아직 서버에서 확인하지 못함 (첫 조회 중 또는 실패)
  bool? isFavorite;

  /// 첫 여부 조회 중
  bool isChecking = false;

  /// 등록·해제 요청 중 (또는 409·404 뒤 현재 여부를 다시 맞추는 중)
  bool isSubmitting = false;

  /// 실패 안내 — 다음 요청을 시작하면 지웁니다.
  String? errorMessage;

  /// 검증된 계정과 TMDB id가 있어야 요청할 수 있습니다.
  bool get canRequest => movieId != null && _accountId != null;

  bool get isBusy => isChecking || isSubmitting;

  /// 응답을 반영해도 되는지 — 화면이 살아 있고, 로그인 세션이 그대로일 때만
  bool get _isCurrent {
    final account = _accountId;
    return !isDisposed &&
        account != null &&
        _guard.isCurrent(_generation, account);
  }

  Future<void> load() async {
    final id = movieId;
    if (id == null || !canRequest || isBusy) return;
    isChecking = true;
    errorMessage = null;
    notifyIfAlive();

    try {
      final value = await _api.isFavorite(id);
      if (!_isCurrent) return;
      isFavorite = value;
    } on DioException catch (error) {
      if (!_isCurrent) return;
      if (await _handleSessionExpired(error)) return;
      errorMessage = '즐겨찾기 상태를 불러오지 못했습니다.';
    } catch (_) {
      if (!_isCurrent) return;
      errorMessage = '즐겨찾기 상태를 불러오지 못했습니다.';
    } finally {
      isChecking = false;
    }
    notifyIfAlive();
  }

  /// 버튼을 누름 — 현재 여부를 모르면(첫 조회 실패) 다시 확인부터 합니다.
  ///
  /// 성공해 상태가 바뀌었으면 바뀐 값(true 등록 / false 해제)을, 아니면 null을 돌려줍니다.
  Future<bool?> toggle() async {
    final id = movieId;
    if (id == null || !canRequest || isBusy) return null;
    final current = isFavorite;
    if (current == null) {
      await load();
      return null;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyIfAlive();

    bool? changedTo;
    try {
      if (current) {
        await _api.removeFavorite(id);
      } else {
        await _api.addFavorite(id);
      }
      if (!_isCurrent) return null;
      isFavorite = !current;
      changedTo = !current;
    } on DioException catch (error) {
      if (!_isCurrent) return null;
      if (await _handleSessionExpired(error)) return null;
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        // 서버는 이미 원하는 상태일 수 있습니다. POST·DELETE를 반복하지 않고 여부를 다시 확인합니다.
        await _syncFromServer(id);
        if (!_isCurrent) return null;
        if (isFavorite != current) changedTo = isFavorite;
      } else if (code == 'MEMBER404_1') {
        // 즐겨찾기 없음(FAVORITE404_1)과 다른 404 — 회원이 없어 요청이 처리되지 않았습니다.
        errorMessage = '회원 정보를 찾을 수 없습니다. 다시 로그인해 주세요.';
      } else {
        errorMessage = '저장하지 못했습니다. 다시 시도해 주세요.';
      }
    } catch (_) {
      if (!_isCurrent) return null;
      errorMessage = '저장하지 못했습니다. 다시 시도해 주세요.';
    } finally {
      isSubmitting = false;
    }
    notifyIfAlive();
    return changedTo;
  }

  /// 409·404 뒤 서버 기준으로 현재 여부를 맞춥니다. 실패하면 이전 버튼 상태를 유지합니다.
  Future<void> _syncFromServer(int id) async {
    try {
      final value = await _api.isFavorite(id);
      if (!_isCurrent) return;
      isFavorite = value;
    } on DioException catch (error) {
      if (!_isCurrent) return;
      if (await _handleSessionExpired(error)) return;
      errorMessage = '저장하지 못했습니다. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent) return;
      errorMessage = '저장하지 못했습니다. 다시 시도해 주세요.';
    }
  }

  /// 세션 만료 코드면 (지금 세션일 때만) 정리를 요청하고 true를 돌려줍니다.
  /// 403이나 로그인 오류(AUTH401_1)는 세션 만료가 아닙니다.
  Future<bool> _handleSessionExpired(DioException error) async {
    if (!isSessionExpiredCode(apiErrorCode(error))) return false;
    if (_isCurrent) await onSessionExpired?.call();
    return true;
  }
}
