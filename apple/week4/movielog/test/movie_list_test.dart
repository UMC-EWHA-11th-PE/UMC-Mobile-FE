import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/data/fake_movie_service.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/data/secure_storage_cleanup.dart';
import 'package:movielog/movie_list_screen.dart';
import 'package:movielog/theme/app_theme.dart';

Widget _app(MovieLoadMode mode, {Key? key}) => MaterialApp(
  theme: AppTheme.light,
  home: MovieListScreen(key: key, loadMode: mode),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('FakeMovieService', () {
    const service = FakeMovieService();

    test('mode에 따라 영화 목록·빈 목록·예외를 돌려준다', () async {
      expect(await service.fetchMovies(), isNotEmpty);
      expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
      expect(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });
  });

  group('영화 목록 상태', () {
    testWidgets('불러오는 동안 로딩을 보여주고, 완료되면 영화를 보여준다', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(MovieLoadMode.success));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(_app(MovieLoadMode.empty));
      await tester.pumpAndSettle();

      expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
      expect(find.text('전체'), findsNothing);
    });

    testWidgets('실패하면 안내 문구와 다시 시도 버튼을 보여주고, 누르면 다시 불러온다', (tester) async {
      await tester.pumpWidget(_app(MovieLoadMode.failure));
      await tester.pumpAndSettle();

      expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('불러오는 중에 화면이 사라져도 오류가 나지 않는다', (tester) async {
      await tester.pumpWidget(_app(MovieLoadMode.success));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });

  group('마지막 선택 장르', () {
    testWidgets('선택한 장르를 저장하고, 다시 들어오면 그 장르로 시작한다', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(MovieLoadMode.success, key: UniqueKey()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();

      expect(await GenrePreference().read(), 'SF');

      // 새 화면으로 다시 들어오기
      await tester.pumpWidget(_app(MovieLoadMode.success, key: UniqueKey()));
      await tester.pumpAndSettle();
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
    });

    test('저장된 값이 없으면 전체를 돌려준다', () async {
      final preference = GenrePreference();
      expect(await preference.read(), '전체');

      await preference.save('드라마');
      await preference.clear();
      expect(await preference.read(), '전체');
    });
  });

  group('재설치 후 Secure Storage 정리', () {
    test('처음 실행할 때만 이전 설치의 값을 지운다', () async {
      FlutterSecureStorage.setMockInitialValues({'access_token': 'old'});
      const secureStorage = FlutterSecureStorage();

      await clearStaleSecureStorageOnFirstInstall();
      expect(await secureStorage.read(key: 'access_token'), isNull);
      expect(await SharedPreferencesAsync().getBool(firstInstallKey), isTrue);

      // 두 번째 실행부터는 로그인 후 저장한 값을 유지
      await secureStorage.write(key: 'access_token', value: 'new');
      await clearStaleSecureStorageOnFirstInstall();
      expect(await secureStorage.read(key: 'access_token'), 'new');
    });
  });
}
