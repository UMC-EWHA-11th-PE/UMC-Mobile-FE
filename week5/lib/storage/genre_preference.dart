
import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  GenrePreference({
    SharedPreferencesAsync? preferences,
  }) : _preferences =
           preferences ?? SharedPreferencesAsync();

  static const String _selectedGenreKey =
      'selected_genre';

  final SharedPreferencesAsync _preferences;

  // 저장된 장르 불러오기
  Future<String> read() async {
    return await _preferences.getString(
          _selectedGenreKey,
        ) ??
        '전체';
  }

  // 선택한 장르 저장하기
  Future<void> save(String genre) async {
    await _preferences.setString(
      _selectedGenreKey,
      genre,
    );
  }

  // 저장된 장르 삭제하기
  Future<void> clear() async {
    await _preferences.remove(
      _selectedGenreKey,
    );
  }
}