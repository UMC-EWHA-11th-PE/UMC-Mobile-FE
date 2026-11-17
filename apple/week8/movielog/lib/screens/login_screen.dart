import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

/// 로그인 화면 — 지금은 라우터 연결 확인용 임시 화면입니다.
///
/// TODO(W8): Figma 로그인 디자인을 받으면 이메일·비밀번호 Form과 POST /v7/auth/login을 연결합니다.
/// 세션 만료 등 [AuthViewModel.message]가 있으면 안내 문구로 보여줍니다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = context.select<AuthViewModel, String?>((vm) => vm.message);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('로그인', style: textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 32),
              MovieLogButton(
                label: '회원가입',
                onPressed: () => context.go('/register'),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
