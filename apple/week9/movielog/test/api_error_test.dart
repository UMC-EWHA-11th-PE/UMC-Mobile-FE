import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/api_error.dart';

DioException _errorWith(Object? data, {int status = 401}) {
  final options = RequestOptions(path: '/v8/members/me');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('공통 오류 body에서 code와 message를 꺼낸다', () {
    final error = _errorWith({
      'isSuccess': false,
      'code': 'AUTH401_3',
      'message': '유효하지 않은 토큰입니다.',
      'result': null,
    });

    expect(apiErrorCode(error), 'AUTH401_3');
    expect(apiErrorMessage(error), '유효하지 않은 토큰입니다.');
  });

  test('body가 Map이 아니면 null을 돌려준다', () {
    final error = _errorWith('<html>Bad Gateway</html>', status: 502);

    expect(apiErrorCode(error), isNull);
    expect(apiErrorMessage(error), isNull);
  });

  test('응답 자체가 없으면(연결 실패) null을 돌려준다', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/v8/members/me'),
      type: DioExceptionType.connectionError,
    );

    expect(apiErrorCode(error), isNull);
    expect(apiErrorMessage(error), isNull);
  });

  test('code·message가 문자열이 아니면 null을 돌려준다', () {
    final error = _errorWith({'code': 401, 'message': null});

    expect(apiErrorCode(error), isNull);
    expect(apiErrorMessage(error), isNull);
  });
}
