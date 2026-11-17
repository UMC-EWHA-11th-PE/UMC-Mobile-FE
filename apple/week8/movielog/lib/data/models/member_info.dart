import 'common_response.dart';

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

/// 공통 응답을 한 번 파싱하고 `result`에서 [MemberInfo]를 꺼냅니다.
/// 형식이 다르거나 result가 없으면 로그인 확정 근거가 없으므로 오류로 봅니다.
MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('내 정보 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
  final member = common.result;
  if (member == null) throw StateError('내 정보 result가 없습니다.');
  return member;
}
