import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_rating_store.dart';

import 'fake_ratings.dart';
import 'fake_tmdb.dart';

RatingDto _rating(int id, {int movieId = 1, String? comment}) =>
    RatingDto.fromJson(
      fakeRatingJson(ratingId: id, movieId: movieId, comment: comment),
    );

void main() {
  group('SessionRatingStore', () {
    test('같은 세션 안에서는 최근 ratingId 순으로 보관하고, 세션이 바뀌면 비운다', () {
      final store = SessionRatingStore()
        ..upsert(1, _rating(3))
        ..upsert(1, _rating(5));

      expect(store.ratings(1).map((r) => r.ratingId), [5, 3]);

      store.remove(1, 5);
      expect(store.ratings(1).map((r) => r.ratingId), [3]);

      // 로그아웃·다시 로그인 등으로 sessionVersion이 바뀌면 이전 세션 값을 쓰지 않습니다.
      expect(store.ratings(2), isEmpty);
      expect(store.ratings(1), isEmpty);
    });

    test('이전 세션에서 늦게 도착한 등록·수정·삭제는 새 세션 보관분을 바꾸지 않는다', () {
      final store = SessionRatingStore()..upsert(3, _rating(10));

      store
        ..upsert(2, _rating(99)) // 로그아웃 전 요청의 늦은 응답
        ..remove(2, 10);

      expect(store.ratings(3).map((r) => r.ratingId), [10]);
    });
  });

  group('LearningMemberSession', () {
    test('가입한 email과 같은 계정으로 로그인했을 때만 memberId를 돌려준다', () {
      final session = LearningMemberSession()
        ..setMember(42, ' Movie@Example.com ');

      expect(session.memberIdFor('movie@example.com'), 42);
      expect(session.memberIdFor('other@example.com'), isNull);
      expect(session.memberIdFor(null), isNull);

      session.clear();
      expect(session.memberIdFor('movie@example.com'), isNull);
    });
  });

  group('MyRatingsViewModel (v7)', () {
    test('memberId가 없으면 공개 조회 없이 이번 세션 등록분만 보여주고 안내한다', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 9)]);
      final store = SessionRatingStore()..upsert(1, _rating(100));
      final viewModel = MyRatingsViewModel(
        server.service,
        fakeTmdbService(),
        sessionRatings: store,
        sessionVersion: 1,
      );

      await viewModel.load();

      expect(server.calls, isEmpty);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [100]);
      expect(viewModel.sessionOnlyNotice, isNotNull);
    });

    test('memberId가 없고 이번 세션 등록분도 없으면 empty + 안내', () async {
      final viewModel = MyRatingsViewModel(
        FakeRatingServer().service,
        fakeTmdbService(),
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.empty);
      expect(viewModel.sessionOnlyNotice, isNotNull);
    });

    test('memberId가 있으면 공개 조회 목록에 아직 반영 안 된 세션 등록분을 앞에 합친다 (중복 제거)', () async {
      final server = FakeRatingServer(
        ratings: [fakeRatingJson(ratingId: 5), fakeRatingJson(ratingId: 4)],
      );
      final store = SessionRatingStore()
        ..upsert(1, _rating(5, comment: '세션 값'))
        ..upsert(1, _rating(6));
      final viewModel = MyRatingsViewModel(
        server.service,
        fakeTmdbService(),
        memberId: 42,
        sessionRatings: store,
        sessionVersion: 1,
      );

      await viewModel.load();

      expect(server.calls, ['GET /v7/members/42/ratings']);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [6, 5, 4]);
      // 서버에도 있는 평점은 서버 값을 기준으로 씁니다.
      expect(viewModel.ratings[1].rating.comment, '최고의 영화!');
      expect(viewModel.sessionOnlyNotice, isNull);
    });

    test('수정·삭제 결과를 이번 세션 보관분에도 반영한다', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 7)]);
      final store = SessionRatingStore()..upsert(1, _rating(7));
      final viewModel = MyRatingsViewModel(
        server.service,
        fakeTmdbService(),
        sessionRatings: store,
        sessionVersion: 1,
      );
      await viewModel.load();

      await viewModel.updateRating(ratingId: 7, score: 2, comment: '바꿈');
      expect(store.ratings(1).single.comment, '바꿈');
      expect(viewModel.ratings.single.rating.comment, '바꿈');

      await viewModel.deleteRating(7);
      expect(store.ratings(1), isEmpty);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('쓰기에서 AUTH401_3을 받으면 세션 정리를 요청하고 WriteFailure', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 7)])
        ..writeError = (
          status: 401,
          code: 'AUTH401_3',
          message: '유효하지 않은 토큰입니다.',
        );
      var expired = 0;
      final viewModel = MyRatingsViewModel(
        server.service,
        fakeTmdbService(),
        memberId: 42,
        onSessionExpired: () async => expired++,
      );
      await viewModel.load();

      await expectLater(
        viewModel.deleteRating(7),
        throwsA(
          isA<WriteFailure>().having(
            (f) => f.message,
            'message',
            '로그인이 만료됐어요. 다시 로그인해 주세요.',
          ),
        ),
      );
      expect(expired, 1);
    });

    test('RATING403_1은 로그아웃하지 않고 목록을 다시 맞춘다', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 7)])
        ..writeError = (
          status: 403,
          code: 'RATING403_1',
          message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
        );
      var expired = 0;
      final viewModel = MyRatingsViewModel(
        server.service,
        fakeTmdbService(),
        memberId: 42,
        onSessionExpired: () async => expired++,
      );
      await viewModel.load();
      server.calls.clear();

      await expectLater(
        viewModel.updateRating(ratingId: 7, score: 3, comment: null),
        throwsA(isA<WriteFailure>()),
      );
      expect(expired, 0);
      expect(server.calls, [
        'PATCH /v7/ratings/7',
        'GET /v7/members/42/ratings',
      ]);
    });

    test('다중 삭제 중 401이면 남은 삭제를 보내지 않고 세션 정리를 요청한다', () async {
      final server = FakeRatingServer(
        ratings: [fakeRatingJson(ratingId: 2), fakeRatingJson(ratingId: 1)],
      );
      var expired = 0;
      final viewModel = MyRatingsViewModel(
        server.service,
        fakeTmdbService(),
        memberId: 42,
        onSessionExpired: () async => expired++,
      );
      await viewModel.load();
      viewModel
        ..startSelection(2)
        ..toggleSelection(1);
      server
        ..calls.clear()
        ..writeError = (status: 401, code: 'AUTH401_4', message: '만료');

      await viewModel.deleteSelected();

      expect(server.calls, hasLength(1)); // 첫 DELETE에서 멈춤
      expect(expired, 1);
      expect(viewModel.isBulkDeleting, isFalse);
    });
  });
}
