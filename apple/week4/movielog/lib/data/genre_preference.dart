import 'package:shared_preferences/shared_preferences.dart';

/// 영화 목록에서 마지막으로 선택한 장르를 기기에 저장합니다.
/// 단순하고 중요하지 않은 설정값이라 shared_preferences를 사용합니다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  /// 장르 필터의 '전체' — 저장된 값이 없을 때의 기본값
  static const allGenres = '전체';

  static const _selectedGenreKey = 'selected_genre';

  final SharedPreferencesAsync _preferences;

  Future<String> read() async {
    return await _preferences.getString(_selectedGenreKey) ?? allGenres;
  }

  Future<void> save(String genre) async {
    await _preferences.setString(_selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
  }
}
