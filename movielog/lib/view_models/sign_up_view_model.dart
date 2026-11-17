import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/login_models.dart';
import '../data/services/auth_api_service.dart';

enum SignUpStatus { idle, submitting, success, error }

/// 8주차 로그인용 계정을 앱에서 만들기 위한 최소 회원가입 ViewModel입니다.
/// (6·7주차의 중복 확인 버튼·세부 오류 분기는 생략)
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final AuthApiService _service;

  SignUpStatus status = SignUpStatus.idle;
  String? message;
  bool _disposed = false;

  Future<void> submit(CreateMemberRequest request) async {
    if (status == SignUpStatus.submitting) return;
    status = SignUpStatus.submitting;
    message = null;
    _notify();

    try {
      await _service.signUp(request);
      status = SignUpStatus.success;
    } on DioException catch (error) {
      status = SignUpStatus.error;
      // 400(비밀번호 형식), 409(이메일·닉네임 중복) 모두 서버 message를 그대로 보여줍니다.
      message = apiErrorMessage(error) ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
