import '../data/models/rating_dto.dart';

/// 지금 로그인 세션에서 등록·수정한 평점을 메모리에 보관합니다.
///
/// v7에는 토큰 기반 "내 평점 목록 GET"이 없고, 로그인·내 정보 응답에 memberId도 없습니다.
/// 그래서 등록·수정 응답으로 받은 평점 객체를 여기에 모아 두고 "내가 등록한 평점"에서
/// 수정·삭제할 수 있게 합니다.
///
/// - [AuthViewModel.sessionVersion]이 바뀌면(로그인·로그아웃·만료·재시작 복원) 이전 세션 값을 버립니다.
/// - 세션 버전은 늘어나기만 하므로, 더 오래된 버전으로 온 요청(로그아웃·회원 전환 뒤 늦게 도착한
///   이전 세션 응답)은 무시합니다. 새 세션의 보관분을 지우거나 섞지 않습니다.
/// - 메모리에만 있으므로 앱을 재시작하면 사라집니다. 재시작 뒤 기존 평점 전체 복원은 지원하지 않습니다.
class SessionRatingStore {
  int? _version;
  final Map<int, RatingDto> _ratings = {};

  /// [version]이 지금 세션이면 true. 더 새 세션이면 이전 값을 버리고 넘어가며,
  /// 더 오래된 세션이면 false — 호출한 쪽은 아무것도 바꾸지 않습니다.
  bool _syncVersion(int version) {
    final current = _version;
    if (current != null && version < current) return false;
    if (current != version) {
      _version = version;
      _ratings.clear();
    }
    return true;
  }

  /// 최근 ratingId가 먼저 오도록 정렬해 돌려줍니다. (공개 조회와 같은 내림차순)
  List<RatingDto> ratings(int version) {
    if (!_syncVersion(version)) return const [];
    return _ratings.values.toList()
      ..sort((a, b) => b.ratingId.compareTo(a.ratingId));
  }

  void upsert(int version, RatingDto rating) {
    if (_syncVersion(version)) _ratings[rating.ratingId] = rating;
  }

  void remove(int version, int ratingId) {
    if (_syncVersion(version)) _ratings.remove(ratingId);
  }
}
