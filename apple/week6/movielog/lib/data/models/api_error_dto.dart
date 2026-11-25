/// v5 API가 실패할 때 내려주는 프레임워크 기본 오류 형식입니다.
///
/// 예) { "message": "존재하지 않는 유저입니다.", "error": "Not Found", "statusCode": 404 }
class ApiErrorDto {
  const ApiErrorDto({
    required this.message,
    required this.error,
    required this.statusCode,
  });

  /// 사용자에게 보여줄 안내 문구
  final String message;

  /// HTTP 상태 이름 (예: Not Found)
  final String? error;
  final int statusCode;

  factory ApiErrorDto.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    return ApiErrorDto(
      // 입력값 검증 실패처럼 문구가 여러 개면 배열로 내려오므로 한 줄로 합칩니다.
      message: message is List ? message.join('\n') : message as String,
      error: json['error'] as String?,
      statusCode: (json['statusCode'] as num).toInt(),
    );
  }
}
