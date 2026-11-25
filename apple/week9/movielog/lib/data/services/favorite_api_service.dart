import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

/// v8 즐겨찾기 API를 호출합니다. 모두 보호 요청이라 AuthInterceptor가 등록된 보호용 Client를 받습니다.
///
/// | 동작      | 요청                              | 성공                                     |
/// | --------- | --------------------------------- | ---------------------------------------- |
/// | 등록      | POST   /v8/favorites { movieId }  | 201 + result = FavoriteResponseDto       |
/// | 내 목록   | GET    /v8/favorites              | 200 + result = 배열 (없으면 [])          |
/// | 여부 조회 | GET    /v8/favorites/{movieId}    | 200 + result = { isFavorite }            |
/// | 해제      | DELETE /v8/favorites/{movieId}    | 200 + result = null                      |
///
/// - 사용자는 서버가 JWT로 구분합니다. memberId를 보내지 않습니다.
/// - 해제·여부 조회 경로에는 favoriteId가 아니라 TMDB movieId를 넣습니다.
/// - page 파라미터가 없습니다. (페이지네이션은 TMDB Discover/Search에만 적용)
/// - 실패(FAVORITE409_1, FAVORITE404_1, AUTH401_2/3/4, MEMBER404_1 등)는
///   8주차처럼 DioException 그대로 ViewModel로 넘깁니다. 전용 예외 클래스를 만들지 않습니다.
class FavoriteApiService {
  FavoriteApiService(this._authDio);

  final Dio _authDio;

  static const _path = '/v8/favorites';

  Future<FavoriteResponseDto> addFavorite(int movieId) async {
    final response = await _authDio.post(_path, data: {'movieId': movieId});
    final result = _parse(
      response.data,
      (value) => FavoriteResponseDto.fromJson(value as Map<String, dynamic>),
    );
    if (result == null) throw StateError('즐겨찾기 등록 result가 없습니다.');
    return result;
  }

  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _authDio.get(_path);
    final result = _parse(
      response.data,
      (value) => [
        for (final item in value as List<dynamic>)
          FavoriteResponseDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return result ?? const [];
  }

  Future<bool> isFavorite(int movieId) async {
    final response = await _authDio.get('$_path/$movieId');
    final result = _parse(
      response.data,
      (value) => FavoriteCheckDto.fromJson(value as Map<String, dynamic>),
    );
    if (result == null) throw StateError('즐겨찾기 여부 result가 없습니다.');
    return result.isFavorite;
  }

  /// 해제 — 평점 삭제와 같은 200이지만 result가 null인 것이 정상입니다.
  Future<void> removeFavorite(int movieId) async {
    final response = await _authDio.delete('$_path/$movieId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 해제 응답: ${response.statusCode}');
    }
  }

  /// 공통 응답을 한 번 파싱하고 result를 꺼냅니다.
  static T? _parse<T>(Object? data, T Function(Object? value) parseResult) {
    if (data is! Map<String, dynamic>) {
      throw StateError('즐겨찾기 응답 형식이 올바르지 않습니다.');
    }
    return CommonResponse<T>.fromJson(data, parseResult).result;
  }
}
