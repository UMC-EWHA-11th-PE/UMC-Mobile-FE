/// `POST /v7/auth/login` 요청 body입니다.
///
/// 비밀번호는 요청에만 담고 어디에도 저장·로그하지 않습니다.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

/// `POST /v7/auth/login` 성공 응답의 `result` payload입니다.
///
/// v7 계약상 memberId는 담기지 않습니다. json['memberId']를 읽거나
/// JWT payload에 있을 것이라고 가정하지 않습니다.
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});

  final String nickname;

  /// MovieLog JWT — TokenStorage에만 저장하고 로그·화면에 남기지 않습니다.
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}
