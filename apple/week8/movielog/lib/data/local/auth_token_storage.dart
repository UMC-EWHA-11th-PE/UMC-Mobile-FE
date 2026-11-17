import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// MovieLog JWT(accessToken)를 기기 보안 저장소에 보관합니다.
///
/// iOS Keychain·Android Keystore로 암호화해 저장하므로 SharedPreferences(평문)에 두지 않습니다.
/// - 메모리 상태(AuthStatus)는 앱이 꺼지면 사라지지만, 이 값은 남아 재실행 때 세션 복원에 씁니다.
/// - 토큰이 있다는 사실만으로 로그인을 확정하지 않습니다. `/v7/members/me` 서버 검증이 필요합니다.
/// - 토큰 문자열은 로그·화면에 남기지 않습니다.
/// - TMDB Read Access Token은 여기에 넣지 않습니다(.env에서 읽음).
class AuthTokenStorage {
  const AuthTokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'movielog_access_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);
}
