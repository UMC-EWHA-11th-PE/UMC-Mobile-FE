/// MovieLog 앱 사용자를 나타내는 모델.
class User {
  const User({required this.id, this.nickname});

  /// 사용자 고유 ID
  final String id;

  /// 사용자가 직접 정한 닉네임.
  ///
  /// 가입 직후에는 아직 정하지 않았을 수 있어서 nullable(`String?`)이다.
  final String? nickname;

  /// 닉네임이 없을 때 대신 보여줄 이름.
  static const String defaultNickname = '게스트';

  /// 화면에 보여줄 이름.
  ///
  /// `nickname` 이 null 이거나 공백뿐이면 [defaultNickname] 을 돌려주므로,
  /// 이 값은 **항상 non-null 이고 비어 있지 않다**.
  String get displayName {
    final trimmed = nickname?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return defaultNickname;
    }
    return trimmed;
  }

  @override
  String toString() => 'User($id, $displayName)';
}
