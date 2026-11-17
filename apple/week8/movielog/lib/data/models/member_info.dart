/// `GET /v7/members/me` 성공 응답의 `result` payload입니다.
///
/// v7 계약상 memberId와 password는 담기지 않습니다.
/// memberId가 필요해 보여도 JWT claim을 추정해 꺼내지 않습니다.
class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String email;
  final String nickname;
  final DateTime createdAt;

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
