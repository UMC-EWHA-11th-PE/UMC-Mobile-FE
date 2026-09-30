import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('MovieLog', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 24),
            FilledButton(
              // go: 스택을 교체하므로 시작 화면으로 되돌아오지 않음
              onPressed: () => context.go('/home'),
              child: const Text('시작하기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              // push: 현재 화면 위에 쌓기 때문에 뒤로 가기가 가능
              onPressed: () => context.push('/register'),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
