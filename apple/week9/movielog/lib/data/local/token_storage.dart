import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// MovieLog JWT(accessToken)를 저장·조회·삭제하는 규칙입니다.
///
/// 로그인·세션 복원·요청 인증 코드가 FlutterSecureStorage에 직접 의존하지 않게 분리해,
/// 테스트에서는 메모리 저장소로 바꿔 끼울 수 있습니다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain·Android Keystore로 암호화해 보관하는 실제 구현입니다.
///
/// - SharedPreferences(평문)는 장르 같은 비민감 값에만 쓰고 토큰은 여기에 둡니다.
/// - 메모리 상태(AuthStatus)는 앱이 꺼지면 사라지지만 이 값은 남아 세션 복원에 씁니다.
/// - 토큰이 있다는 사실만으로 로그인을 확정하지 않습니다. `/v8/members/me` 검증이 필요합니다.
/// - 비밀번호와 TMDB Read Access Token은 저장하지 않습니다.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
