import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

import 'fake_favorites.dart';

const _email = 'mingo@example.com';

FavoriteDetailViewModel _viewModel(
  FakeFavoriteServer server, {
  SessionGuard? guard,
  int? movieId = 550,
  List<bool>? expired,
}) {
  return FavoriteDetailViewModel(
    server.service,
    movieId: movieId,
    guard: guard ?? (SessionGuard()..startSession(_email)),
    onSessionExpired: () async => expired?.add(true),
  );
}

void main() {
  test('처음 진입하면 movieId로 현재 여부를 확인한다', () async {
    final server = FakeFavoriteServer(movieIds: [550]);
    final viewModel = _viewModel(server);

    await viewModel.load();

    expect(viewModel.isFavorite, isTrue);
    expect(server.calls, ['GET /v8/favorites/550']);
  });

  test('등록 → POST, 해제 → DELETE. 성공한 뒤에만 상태가 바뀐다', () async {
    final server = FakeFavoriteServer();
    final viewModel = _viewModel(server);
    await viewModel.load();

    final gate = Completer<void>();
    server.gate = gate.future;
    final adding = viewModel.toggle();
    // 요청 중: 로딩, 아직 이전 상태
    expect(viewModel.isSubmitting, isTrue);
    expect(viewModel.isFavorite, isFalse);
    gate.complete();
    server.gate = null;
    expect(await adding, isTrue);
    expect(viewModel.isFavorite, isTrue);

    expect(await viewModel.toggle(), isFalse);
    expect(viewModel.isFavorite, isFalse);
    expect(server.calls, [
      'GET /v8/favorites/550',
      'POST /v8/favorites',
      'DELETE /v8/favorites/550',
    ]);
  });

  test('요청 중에 다시 눌러도 요청을 한 번만 보낸다', () async {
    final server = FakeFavoriteServer();
    final viewModel = _viewModel(server);
    await viewModel.load();

    final gate = Completer<void>();
    server.gate = gate.future;
    final first = viewModel.toggle();
    expect(await viewModel.toggle(), isNull);
    gate.complete();
    await first;

    expect(server.calls.where((c) => c.startsWith('POST')), hasLength(1));
  });

  test('FAVORITE409_1이면 POST를 반복하지 않고 GET으로 현재 여부를 맞춘다', () async {
    final server = FakeFavoriteServer();
    final viewModel = _viewModel(server);
    await viewModel.load(); // 화면은 false
    server.movieIds.add(550); // 다른 기기에서 이미 등록

    expect(await viewModel.toggle(), isTrue);
    expect(viewModel.isFavorite, isTrue);
    expect(viewModel.errorMessage, isNull);
    expect(server.calls, [
      'GET /v8/favorites/550',
      'POST /v8/favorites',
      'GET /v8/favorites/550',
    ]);
  });

  test('FAVORITE404_1이면 DELETE를 반복하지 않고 GET으로 현재 여부를 맞춘다', () async {
    final server = FakeFavoriteServer(movieIds: [550]);
    final viewModel = _viewModel(server);
    await viewModel.load(); // 화면은 true
    server.movieIds.clear(); // 이미 해제됨

    expect(await viewModel.toggle(), isFalse);
    expect(viewModel.isFavorite, isFalse);
    expect(server.calls.last, 'GET /v8/favorites/550');
    expect(server.calls.where((c) => c.startsWith('DELETE')), hasLength(1));
  });

  test('네트워크 실패는 안내만 하고 이전 버튼 상태를 유지한다', () async {
    final server = FakeFavoriteServer(movieIds: [550]);
    final viewModel = _viewModel(server);
    await viewModel.load();
    server.failMethods.add('DELETE');

    expect(await viewModel.toggle(), isNull);
    expect(viewModel.isFavorite, isTrue);
    expect(viewModel.errorMessage, '저장하지 못했습니다. 다시 시도해 주세요.');
  });

  test('MEMBER404_1은 즐겨찾기 없음과 구분해 안내하고 세션을 정리하지 않는다', () async {
    final server = FakeFavoriteServer();
    final expired = <bool>[];
    final viewModel = _viewModel(server, expired: expired);
    await viewModel.load();
    server.nextError = (status: 404, code: 'MEMBER404_1');

    await viewModel.toggle();
    expect(viewModel.isFavorite, isFalse);
    expect(viewModel.errorMessage, contains('회원 정보'));
    expect(expired, isEmpty);
    expect(server.calls.last, 'POST /v8/favorites'); // 다시 GET하지 않음
  });

  test('현재 세션의 AUTH401_4는 세션 만료를 요청한다', () async {
    final server = FakeFavoriteServer();
    final expired = <bool>[];
    final viewModel = _viewModel(server, expired: expired);
    await viewModel.load();
    server.nextError = (status: 401, code: 'AUTH401_4');

    await viewModel.toggle();
    expect(expired, [true]);
  });

  test('403·AUTH401_1은 세션 만료가 아니다', () async {
    final server = FakeFavoriteServer();
    final expired = <bool>[];
    final viewModel = _viewModel(server, expired: expired);
    await viewModel.load();

    server.nextError = (status: 403, code: 'COMMON403');
    await viewModel.toggle();
    server.nextError = (status: 401, code: 'AUTH401_1');
    await viewModel.toggle();

    expect(expired, isEmpty);
    expect(viewModel.isFavorite, isFalse);
  });

  test('이전 세션에서 늦게 도착한 401은 현재 세션을 만료시키지 않는다', () async {
    final server = FakeFavoriteServer();
    final guard = SessionGuard()..startSession('a@example.com');
    final expired = <bool>[];
    final viewModel = _viewModel(server, guard: guard, expired: expired);
    await viewModel.load();

    final gate = Completer<void>();
    server.gate = gate.future;
    server.nextError = (status: 401, code: 'AUTH401_4');
    final pending = viewModel.toggle();

    // 응답이 오기 전에 다른 계정으로 로그인
    guard.startSession('b@example.com');
    gate.complete();
    await pending;

    expect(expired, isEmpty);
  });

  test('이전 세션의 늦은 성공 응답은 반영하지 않는다', () async {
    final server = FakeFavoriteServer();
    final guard = SessionGuard()..startSession(_email);
    final viewModel = _viewModel(server, guard: guard);
    await viewModel.load();

    final gate = Completer<void>();
    server.gate = gate.future;
    final pending = viewModel.toggle();
    guard.invalidate(); // 로그아웃
    gate.complete();

    expect(await pending, isNull);
    expect(viewModel.isFavorite, isFalse);
  });

  test('화면을 벗어난(dispose) 뒤 도착한 응답은 무시하고 오류도 나지 않는다', () async {
    final server = FakeFavoriteServer();
    final gate = Completer<void>();
    server.gate = gate.future;
    final viewModel = _viewModel(server);
    final loading = viewModel.load();

    viewModel.dispose();
    gate.complete();
    await loading;

    expect(viewModel.isFavorite, isNull);
  });

  test('검증된 계정(email)이 없으면 요청하지 않는다', () async {
    final server = FakeFavoriteServer();
    final viewModel = _viewModel(server, guard: SessionGuard());

    await viewModel.load();
    await viewModel.toggle();

    expect(viewModel.canRequest, isFalse);
    expect(server.calls, isEmpty);
  });

  test('첫 조회에 실패하면 버튼을 눌렀을 때 여부 확인부터 다시 한다', () async {
    final server = FakeFavoriteServer(movieIds: [550])..failMethods.add('GET');
    final viewModel = _viewModel(server);
    await viewModel.load();
    expect(viewModel.isFavorite, isNull);
    expect(viewModel.errorMessage, isNotNull);

    server.failMethods.clear();
    expect(await viewModel.toggle(), isNull);
    expect(viewModel.isFavorite, isTrue);
    expect(server.calls.where((c) => c.startsWith('POST')), isEmpty);
  });
}
