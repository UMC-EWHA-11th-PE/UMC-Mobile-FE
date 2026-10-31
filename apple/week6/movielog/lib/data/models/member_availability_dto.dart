/// v5 닉네임·이메일 중복 체크 API의 응답입니다. 예) { "available": true }
/// - GET /v5/members/nickname/{nickname}
/// - GET /v5/members/email/{email}
///
/// v5는 공통 Wrapper가 없어 이 객체가 응답 본문 그대로입니다.
class MemberAvailabilityDto {
  const MemberAvailabilityDto({required this.available});

  /// 사용할 수 있는 값이면 true, 이미 사용 중이면 false
  final bool available;

  factory MemberAvailabilityDto.fromJson(Map<String, dynamic> json) {
    return MemberAvailabilityDto(available: json['available'] as bool);
  }
}
