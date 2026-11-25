# MovieLog — 9주차 (v8 즐겨찾기 · 더 보기 · 검색)

8주차 v7 API는 v8에서도 계약이 같아 경로의 `/v7`만 `/v8`로 바꿨습니다.

## 9주차에 추가한 것

### 즐겨찾기 (`/v8/favorites`, 모두 JWT 보호 요청)

영화 상세의 제목·정보 텍스트 오른쪽에 북마크 버튼을 두고(3주차 하단 mock 버튼 제거), 화면 initState에서 여부를 한 번 조회합니다.
등록·해제 중에는 북마크 자리에만 로딩이 보이고, 서버 성공을 확인한 뒤에만 아이콘을 바꿉니다(optimistic update 없음). 결과는 Snackbar로 안내합니다.

| 목적 | 요청 | 성공 |
| --- | --- | --- |
| 등록 | `POST /v8/favorites` `{ "movieId": 550 }` | 201, result = `{ favoriteId, movieId, createdAt }` |
| 내 목록 | `GET /v8/favorites` | 200, result = 배열 (없으면 `[]`) |
| 특정 영화 여부 | `GET /v8/favorites/{movieId}` | 200, result = `{ "isFavorite": true }` |
| 해제 | `DELETE /v8/favorites/{movieId}` | 200, result = `null` |

- 사용자는 서버가 JWT로 구분합니다. memberId를 보내거나 JWT 안에서 추측하지 않습니다.
- 해제·여부 경로에는 `favoriteId`가 아니라 TMDB `movieId`를 넣습니다.
- 즐겨찾기 응답에는 제목·포스터가 없어, `movieId`로 TMDB `/movie/{id}`를 조회해 카드에 합칩니다.
  한 번에 최대 5개만 요청하고(`mapBounded`), 실패한 카드만 placeholder와 "정보 다시 불러오기"를 보여줍니다.

| 오류 | 화면 처리 |
| --- | --- |
| `FAVORITE409_1` 이미 등록 / `FAVORITE404_1` 이미 해제 | 같은 요청을 반복하지 않고 여부 GET으로 버튼을 맞춤 |
| `AUTH401_2/3/4` | 지금 세션의 응답일 때만 세션 만료 처리 (`SessionGuard`) |
| `MEMBER404_1` | 회원 없음 안내 — 즐겨찾기 없음(404)과 구분, 로그아웃하지 않음 |
| 네트워크·저장소 실패 | 실패 안내, 이전 버튼 상태 유지 |

### 세션·상태 보호

- `AuthSessionBridge`가 `AuthViewModel`의 `sessionVersion`과 `/members/me`로 확인한 email을 `SessionGuard`에 전달합니다.
  같은 email로 다시 로그인해도 새 세션입니다.
- 상세 즐겨찾기·내 즐겨찾기 ViewModel은 `ValueKey('email:generation')`으로 만들어, 계정이 바뀌면 새로 만듭니다.
  내 정보(`member`)가 준비되고 SessionGuard와 일치하기 전에는 만들지 않고 로딩(실패 시 "내 정보 다시 조회")을 보여 줍니다.
- `SafeNotify` mixin으로 화면이 사라진 뒤에는 `notifyListeners()`를 부르지 않습니다.

### 영화 목록 "더 보기"와 검색

- 영화 목록은 5주차의 "Discover 최대 30개 수집" 대신 `PagedMoviesViewModel`로 첫 page만 불러오고,
  그리드 아래 Footer로 다음 page를 이어 붙입니다. (더 보기 · 추가 로딩 · 다음 페이지 오류 · 마지막 페이지)
  홈의 인기 영화 5개는 그대로입니다.
- 장르·검색어가 바뀌면 요청 generation을 올려 이전 조건의 늦은 응답을 버립니다.
- 5주차 동작(장르 저장, Pull to Refresh, 장르 변경 실패 시 재시도 Dialog)은 유지합니다.
- TMDB page는 1~500까지라 `total_pages`가 더 커도 501은 요청하지 않습니다. 다음 page 실패는 `nextPage`를 그대로 둬 같은 page를 다시 요청합니다.
- 탭 헤더의 검색 버튼은 `/movies/search`(TMDB `/search/movie`) 화면을 하단 탭 없이 엽니다.
  정적인 `/movies/search`를 동적인 `/movies/:movieId`보다 먼저 등록해 `search`가 영화 ID로 해석되지 않게 합니다.
  빈 검색어는 보내지 않고, 처음 진입(idle)과 결과 없음(empty)을 구분합니다.

## 9주차 검증 기록

### 자동 검증 (2026-11-25)

- `flutter analyze` — No issues found
- `flutter test` — 290개 전부 통과

| 체크 항목 | 확인한 테스트 |
| --- | --- |
| 상세 즐겨찾기 등록·해제·실패·재조회가 movieId 기준 | `favorite_detail_view_model_test.dart`, `movie_detail_test.dart` (경로 `/v8/favorites/{movieId}`, 409·404 뒤 여부 재조회, 실패 시 이전 아이콘 유지, 첫 조회 실패 시 새로고침) |
| 내 즐겨찾기 진입·복귀 갱신·뒤로가기·하단 탭 경계 | `favorites_test.dart` (마이 → 내 즐겨찾기는 하단 탭 없음, 상세에서 해제 후 복귀 시 사라짐, 뒤로가면 마이페이지) |
| 홈 인기 5개 유지, 목록 30개 제한 없이 더 보기 | 홈 코드(`movie_home_view_model.dart`, `home_screen.dart`)는 8주차와 동일. `movie_list_test.dart` (45개를 page 3까지) |
| 초기·추가·빈·오류·끝 상태, 실패한 page 그대로 재시도 | `movie_list_test.dart`, `movie_search_test.dart` (실패 후 같은 page 재요청, 500 page 상한) |
| 검색·장르 변경·화면 이탈·로그아웃·계정 전환에서 늦은 응답 무시 | 장르 변경 늦은 다음 page, 이전 검색어 늦은 응답, dispose 뒤 응답, 로그아웃 뒤 목록·401, 계정 전환 뒤 상세·목록 |
| TMDB 보충 1건 실패로 목록 전체가 비지 않음 | `favorites_test.dart` (한 카드만 placeholder + 정보 다시 불러오기) |
| 토큰을 다른 호스트·로그에 보내지 않음 | `favorite_core_test.dart`, `auth_interceptor_test.dart` (workbook 호스트의 보호 경로에만 JWT), 로그는 Authorization 마스킹·JWT 가림 |
| 세션 만료 1회 정리, 403·네트워크 실패는 로그아웃 안 함 | `favorites_test.dart` (AUTH401_4 → 토큰 삭제 1회 + /login, 403·연결 실패는 signedIn 유지) |

### 수동 검증 (iOS 시뮬레이터, 실제 v8 서버)

| 순서 | 요청 | 결과 |
| --- | --- | --- |
| 이전 주차 토큰으로 시작 | `GET /v8/members/me` | 401 → 세션 정리, 로그인 화면에 만료 안내 |
| v8 회원가입 → 로그인 | `POST /v8/members` → `POST /v8/auth/login` | 201 → 200, signedIn |
| 상세 진입 | `GET /v8/favorites/{movieId}` | 200, 북마크에 서버 여부 반영 |
| 북마크 등록 | `POST /v8/favorites` | 201, 채워진 북마크 + Snackbar |
| 내 즐겨찾기 | `GET /v8/favorites` | 200, 등록한 영화 카드 표시 |
| 카드 → 상세 재진입 | `GET /v8/favorites/{movieId}` | 200, 등록 상태로 시작 |
| 북마크 해제 → 뒤로가기 | `DELETE /v8/favorites/{movieId}` → `GET /v8/favorites` | 200(result null) → 목록에서 사라짐 |
| 영화 목록·검색 | TMDB `discover/movie?page=1`, `search/movie?query=…&page=1` | 첫 page 표시 |

- 실행 로그에서 JWT 형태 문자열·`Bearer` 토큰 값이 0건임을 확인했습니다. (TMDB 헤더는 `Bearer ***`로 마스킹)
- Challenge는 선택하지 않았습니다.

## 내 평점 목록: 현재 계약의 한계 (8주차부터)

### v8 API에도 없는 것 (v7과 계약 동일)

- 로그인(`POST /v8/auth/login`)과 내 정보(`GET /v8/members/me`) 응답에 **memberId가 없습니다.**
- **토큰으로 "내 평점 목록"을 조회하는 GET이 없습니다.** 평점 조회는 공개 API `GET /v8/members/{memberId}/ratings` 하나뿐이고 memberId path가 필요합니다.
- 명세에 없는 JWT claim(payload의 회원 번호 등)은 추정해서 꺼내지 않습니다.

그래서 "로그인한 계정의 기존 평점 전체를 언제든 불러오기"는 지금 계약으로는 구현할 수 없습니다.

### 앱이 대신 하는 일

"내가 등록한 평점" 화면은 아래 두 곳을 합쳐서 보여줍니다.

| 출처 | 언제 | 내용 |
| --- | --- | --- |
| 이번 로그인 세션의 등록분 | 항상 | 등록(`POST /v8/ratings`)과 수정(`PATCH /v8/ratings/{id}`) 응답의 Rating 객체를 메모리(`SessionRatingStore`)에 보관합니다. 이 평점들은 JWT로 수정·삭제할 수 있습니다. |
| 공개 조회 | 이 앱에서 회원가입한 계정과 **같은 email로 로그인했을 때만** | 가입 응답의 memberId를 email과 함께 기억해 두었다가(`LearningMemberSession`) `GET /v8/members/{memberId}/ratings`를 호출합니다. 토큰은 보내지 않습니다. |

- 다른 계정으로 로그인하면 기억해 둔 memberId를 쓰지 않습니다. 다른 회원의 평점을 내 평점처럼 보여주지 않기 위해서입니다.
- 공개 조회를 할 수 없으면 화면에 **"이번 로그인에서 등록한 평점만 보여요. 이전에 남긴 평점은 아직 불러올 수 없어요."** 라는 안내를 함께 표시합니다.
- memberId는 조회 경로에만 씁니다. 등록·수정·삭제 요청에는 memberId가 없고, 회원 식별과 소유자 확인(`RATING403_1`)은 서버가 JWT로 합니다.

### 지원하지 않는 것 (완료 기능으로 표시하지 않음)

- **앱 재시작 뒤 기존 내 평점 전체 복원.** 세션 등록분과 가입 memberId는 메모리에만 있어서 앱을 다시 켜면 사라집니다. 로그인 상태(JWT)는 secure storage로 복원되지만 평점 목록은 복원되지 않습니다.
- **다른 기기나 이전 설치에서 가입한 계정의 기존 평점 조회.** 이 앱에서 가입하지 않았으면 memberId를 알 방법이 없습니다.
- 로그아웃, 세션 만료, 다른 계정으로 로그인하면 이전 세션의 등록분을 버립니다. 늦게 도착한 이전 세션 응답도 반영하지 않습니다.

### 계약이 바뀌면

- 서버가 토큰 기반 "내 평점 목록 GET"(예: `GET /v8/ratings/me`)을 제공하거나 내 정보 응답에 memberId를 담으면, `MyRatingsViewModel.load()`의 조회 출처만 바꾸면 됩니다.
- 그때는 `SessionRatingStore`와 email 기반 memberId 매칭(`LearningMemberSession.memberIdFor`)을 정리할 수 있습니다.

### 관련 코드

- [`lib/view_models/session_rating_store.dart`](lib/view_models/session_rating_store.dart) — 세션 등록분 보관, 이전 세션 응답 무시
- [`lib/view_models/learning_member_session.dart`](lib/view_models/learning_member_session.dart) — 가입 memberId를 email과 묶어 같은 계정일 때만 반환
- [`lib/view_models/my_ratings_view_model.dart`](lib/view_models/my_ratings_view_model.dart) — 두 출처 합치기, `sessionOnlyNotice`
- [`lib/data/services/rating_api_service.dart`](lib/data/services/rating_api_service.dart) — 공개 조회는 public Client, 쓰기는 auth Client
