import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필(닉네임) 수정 화면의 저장과 오류 처리를 담당합니다.
///
/// 오류는 보여줄 위치로 나눕니다.
/// - 입력칸의 문제(길이 COMMON400, 중복 MEMBER409_1): [nicknameError] → 입력칸 아래, 입력값 유지
/// - 입력과 무관한 문제(네트워크 등): [message] → Snackbar, 로그아웃하지 않음
/// - 세션 만료(AUTH401_2/3/4): [AuthViewModel.expireSession] → Router가 /login으로 이동
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;

  /// 입력 필드 아래에 보여줄 오류
  String? nicknameError;

  /// Snackbar로 보여줄 오류(네트워크 등)
  String? message;

  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  /// 서버에 보내기 전에 확인할 수 있는 규칙은 클라이언트에서 먼저 검사합니다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 입력이 바뀌면 이전 오류는 더 이상 지금 값에 대한 것이 아니므로 지웁니다.
  void clearNicknameError() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  /// 저장에 성공하면 true — 화면은 Snackbar 후 마이페이지로 돌아갑니다.
  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지

    final version = _auth.sessionVersion;
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        _auth.member == null) {
      return false;
    }
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료로 처리합니다.
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    nicknameError = null;
    message = null;
    _notify();

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (_isStale(version)) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여줍니다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (_isStale(version)) return false;
      status = EditProfileStatus.failure;
      switch (apiErrorCode(error)) {
        case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
          // 세션 만료: 이동은 Router가, 안내는 로그인 화면이 처리합니다.
          await _auth.expireSession();
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃하지 않음
      }
    } catch (_) {
      if (_isStale(version)) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  /// 화면이 닫혔거나 로그아웃·계정 전환 뒤 도착한 응답은 반영하지 않습니다.
  bool _isStale(int version) =>
      _disposed ||
      version != _auth.sessionVersion ||
      _auth.status != AuthStatus.signedIn;

  /// 화면이 사라진 뒤 도착한 응답이 notifyListeners()를 호출하지 않게 막습니다.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
