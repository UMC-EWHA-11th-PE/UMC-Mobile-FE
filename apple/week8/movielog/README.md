# MovieLog — 8주차 (v7 JWT 인증)

## 내 평점 목록: 현재 계약의 한계

### v7 API에 없는 것

- 로그인(`POST /v7/auth/login`)과 내 정보(`GET /v7/members/me`) 응답에 **memberId가 없습니다.**
- **토큰으로 "내 평점 목록"을 조회하는 GET이 없습니다.** 평점 조회는 공개 API `GET /v7/members/{memberId}/ratings` 하나뿐이고 memberId path가 필요합니다.
- 명세에 없는 JWT claim(payload의 회원 번호 등)은 추정해서 꺼내지 않습니다.

그래서 "로그인한 계정의 기존 평점 전체를 언제든 불러오기"는 지금 계약으로는 구현할 수 없습니다.

### 앱이 대신 하는 일

"내가 등록한 평점" 화면은 아래 두 곳을 합쳐서 보여줍니다.

| 출처 | 언제 | 내용 |
| --- | --- | --- |
| 이번 로그인 세션의 등록분 | 항상 | 등록(`POST /v7/ratings`)과 수정(`PATCH /v7/ratings/{id}`) 응답의 Rating 객체를 메모리(`SessionRatingStore`)에 보관합니다. 이 평점들은 JWT로 수정·삭제할 수 있습니다. |
| 공개 조회 | 이 앱에서 회원가입한 계정과 **같은 email로 로그인했을 때만** | 가입 응답의 memberId를 email과 함께 기억해 두었다가(`LearningMemberSession`) `GET /v7/members/{memberId}/ratings`를 호출합니다. 토큰은 보내지 않습니다. |

- 다른 계정으로 로그인하면 기억해 둔 memberId를 쓰지 않습니다. 다른 회원의 평점을 내 평점처럼 보여주지 않기 위해서입니다.
- 공개 조회를 할 수 없으면 화면에 **"이번 로그인에서 등록한 평점만 보여요. 이전에 남긴 평점은 아직 불러올 수 없어요."** 라는 안내를 함께 표시합니다.
- memberId는 조회 경로에만 씁니다. 등록·수정·삭제 요청에는 memberId가 없고, 회원 식별과 소유자 확인(`RATING403_1`)은 서버가 JWT로 합니다.

### 지원하지 않는 것 (완료 기능으로 표시하지 않음)

- **앱 재시작 뒤 기존 내 평점 전체 복원.** 세션 등록분과 가입 memberId는 메모리에만 있어서 앱을 다시 켜면 사라집니다. 로그인 상태(JWT)는 secure storage로 복원되지만 평점 목록은 복원되지 않습니다.
- **다른 기기나 이전 설치에서 가입한 계정의 기존 평점 조회.** 이 앱에서 가입하지 않았으면 memberId를 알 방법이 없습니다.
- 로그아웃, 세션 만료, 다른 계정으로 로그인하면 이전 세션의 등록분을 버립니다. 늦게 도착한 이전 세션 응답도 반영하지 않습니다.

### 계약이 바뀌면

- 서버가 토큰 기반 "내 평점 목록 GET"(예: `GET /v7/ratings/me`)을 제공하거나 내 정보 응답에 memberId를 담으면, `MyRatingsViewModel.load()`의 조회 출처만 바꾸면 됩니다.
- 그때는 `SessionRatingStore`와 email 기반 memberId 매칭(`LearningMemberSession.memberIdFor`)을 정리할 수 있습니다.

### 관련 코드

- [`lib/view_models/session_rating_store.dart`](lib/view_models/session_rating_store.dart) — 세션 등록분 보관, 이전 세션 응답 무시
- [`lib/view_models/learning_member_session.dart`](lib/view_models/learning_member_session.dart) — 가입 memberId를 email과 묶어 같은 계정일 때만 반환
- [`lib/view_models/my_ratings_view_model.dart`](lib/view_models/my_ratings_view_model.dart) — 두 출처 합치기, `sessionOnlyNotice`
- [`lib/data/services/rating_api_service.dart`](lib/data/services/rating_api_service.dart) — 공개 조회는 public Client, 쓰기는 auth Client
