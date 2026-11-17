import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env를 다 읽기 전에 Token을 꺼내면 빈 값이 되므로 runApp 전에 기다립니다.
  await dotenv.load(fileName: '.env');
  // 재설치 후 Keychain 정리와 세션 복원은 AuthViewModel이 스플래시를 보여주며 진행합니다.
  runApp(const MovieLogApp());
}
