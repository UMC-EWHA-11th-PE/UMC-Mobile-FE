import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';

class MemberCheckException implements Exception {
  const MemberCheckException(this.message);

  final String message;
}

/// 회원가입 중복 체크 API를 호출합니다.
/// - GET /members/nickname/{nickname}
/// - GET /members/email/{email}
class MemberService {
  MemberService({http.Client? client}) : _client = client ?? ApiConfig.client;

  final http.Client _client;

  /// 사용할 수 있는 닉네임이면 true
  Future<bool> isNicknameAvailable(String nickname) =>
      _checkAvailable(['members', 'nickname', nickname]);

  /// 사용할 수 있는 이메일이면 true
  Future<bool> isEmailAvailable(String email) =>
      _checkAvailable(['members', 'email', email]);

  /// 응답 예) { "available": true }
  Future<bool> _checkAvailable(List<String> pathSegments) async {
    try {
      final response = await _client.get(ApiConfig.uri(pathSegments));
      if (response.statusCode != 200) {
        throw MemberCheckException('중복 확인에 실패했습니다. (${response.statusCode})');
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['available'] as bool;
    } on MemberCheckException {
      rethrow;
    } catch (_) {
      throw const MemberCheckException('서버에 연결할 수 없습니다.');
    }
  }
}
