import 'package:flutter/foundation.dart';

/// 이 앱에서 회원가입한 계정의 memberId를 email과 함께 기억합니다.
///
/// v7 로그인·내 정보 응답에는 memberId가 없지만, 공개 "유저별 평점 조회"는 memberId path를 씁니다.
/// 그래서 가입 응답으로 받은 memberId를 **같은 email로 로그인했을 때만** 공개 조회에 씁니다.
///
/// - 다른 계정으로 로그인하면 [memberIdFor]가 null — 다른 회원의 평점을 내 평점으로 보여주지 않습니다.
/// - memberId는 인증 수단이 아닙니다. 평점 쓰기는 JWT로만 하고 memberId를 보내지 않습니다.
/// - JWT claim에서 memberId를 추정해 꺼내지 않습니다.
/// - 메모리에만 있으므로 앱을 재시작하면 사라집니다. (SharedPreferences에 저장하지 않음)
class LearningMemberSession extends ChangeNotifier {
  int? _memberId;
  String? _email;

  /// 마지막으로 가입한 계정의 memberId (계정 확인 없이 쓰지 말고 [memberIdFor]를 씁니다)
  int? get memberId => _memberId;

  /// 가입 응답의 memberId와 email을 함께 기억합니다.
  void setMember(int memberId, String email) {
    _memberId = memberId;
    _email = email.trim().toLowerCase();
    notifyListeners();
  }

  /// 지금 로그인한 계정([email])이 이 앱에서 가입한 계정과 같을 때만 memberId를 돌려줍니다.
  int? memberIdFor(String? email) {
    if (email == null || _email == null) return null;
    return _email == email.trim().toLowerCase() ? _memberId : null;
  }

  void clear() {
    _memberId = null;
    _email = null;
    notifyListeners();
  }
}
