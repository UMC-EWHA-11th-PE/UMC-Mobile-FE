import 'package:dio/dio.dart';

import 'package:movielog/data/services/member_check_service.dart';

/// 서버 없이 v5 중복 체크 응답을 흉내 내는 [MemberCheckService]를 만듭니다.
///
/// - [taken]에 든 닉네임·이메일이면 { "available": false }, 아니면 true
/// - [fail]이 true면 연결 오류(DioException)
/// - [gate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — 늦은 응답 확인용
/// - [requests]에 보낸 요청 path를 순서대로 기록
MemberCheckService fakeMemberCheckService({
  Set<String> taken = const {},
  bool fail = false,
  Future<void>? gate,
  List<String>? requests,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests?.add(options.path);
          if (gate != null) await gate;

          if (fail) {
            return handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: '테스트용 연결 실패',
              ),
            );
          }

          final value = Uri.decodeComponent(options.path.split('/').last);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'available': !taken.contains(value)},
            ),
          );
        },
      ),
    );
  return MemberCheckService(dio);
}
