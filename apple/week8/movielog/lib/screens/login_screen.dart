import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/labeled_input.dart';
import '../widgets/movielog_button.dart';

/// 로그인 화면 (W8-03 기본 · W8-04 요청 중 · W8-05 실패)
///
/// 버튼은 [AuthViewModel.login]만 호출하고 직접 `/home`으로 이동하지 않습니다.
/// 성공하면 status가 signedIn이 되고 Router(redirect)가 홈으로 보냅니다.
/// - 요청 중(authenticating): 버튼 로딩, 입력·회원가입 이동 막기
/// - AUTH401_1·COMMON400: 비밀번호 입력칸 빨간 테두리 + 아래 문구 ([AuthViewModel.loginError])
/// - 연결 실패·토큰 저장 실패: Snackbar ([AuthViewModel.message])
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    // 화면이 열려 있는 중 만료되는 경우는 리스너로, 이미 만료된 상태로 처음 열리는
    // 경우(보호 화면에서 401 → redirect)는 첫 프레임 뒤 확인으로 처리합니다.
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
  }

  /// 만료로 쫓겨난 경우에만 한 번 안내합니다. 직접 로그아웃·AUTH401_1은 sessionExpired가 꺼져 있습니다.
  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 같은 Snackbar가 반복되지 않게 바로 끕니다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// 이메일·비밀번호가 모두 입력돼 있고, 요청 중·토큰 정리 중이 아니어야 로그인할 수 있습니다.
  bool _canSubmit(AuthViewModel auth) =>
      auth.status != AuthStatus.authenticating &&
      !auth.storageCleanupInProgress &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  /// 입력이 바뀌면 버튼 활성화를 다시 계산하고, 이전 로그인 실패 문구를 지웁니다.
  void _onChanged() {
    context.read<AuthViewModel>().clearLoginError();
    setState(() {});
  }

  Future<void> _submit() async {
    final auth = context.read<AuthViewModel>();
    if (!_canSubmit(auth)) return;
    FocusScope.of(context).unfocus();

    await auth.login(_emailController.text, _passwordController.text);
    // 성공하면 Router가 이 화면을 홈으로 바꾸므로 mounted가 false가 됩니다.
    if (!mounted) return;

    final message = auth.message;
    if (auth.status == AuthStatus.signedOut && message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isSubmitting = auth.status == AuthStatus.authenticating;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(
        title: '로그인',
        titleStyle: AppTheme.appBarTitleBold,
        showBack: false,
      ),
      body: SafeArea(
        // 키보드가 올라와도 입력창이 가려지지 않도록 스크롤 가능하게 만듭니다.
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 84,
                height: 84,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 8),
              Text(
                'MovieLog에 로그인',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.detailText,
                ),
              ),
              const SizedBox(height: 32),
              LabeledInput(
                label: '이메일',
                child: TextField(
                  controller: _emailController,
                  readOnly: isSubmitting,
                  onChanged: (_) => _onChanged(),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  style: movieLogInputTextStyle(context),
                  decoration: movieLogInputDecoration(
                    context,
                    hint: '이메일을 입력해 주세요',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LabeledInput(
                label: '비밀번호',
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  readOnly: isSubmitting,
                  onChanged: (_) => _onChanged(),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: movieLogInputTextStyle(context),
                  decoration: movieLogInputDecoration(
                    context,
                    hint: '비밀번호를 입력해 주세요',
                    hasError: auth.loginError != null,
                  ),
                ),
              ),
              // 로그인 실패 문구 (W8-05) — 입력창 왼쪽 끝에 맞추고, 문구가 없어도 같은
              // 높이를 비워 둬서 문구가 나타나도 아래 버튼이 움직이지 않습니다.
              const SizedBox(height: 8),
              SizedBox(
                height: 16,
                child: auth.loginError == null
                    ? null
                    : Text(
                        auth.loginError!,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: colors.error,
                        ),
                      ),
              ),
              const SizedBox(height: 88),
              // 요청 중: 회색 배경 + 로딩 표시 (W8-04)
              MovieLogButton(
                label: '로그인',
                width: double.infinity,
                isLoading: isSubmitting,
                onPressed: _canSubmit(auth) ? _submit : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '계정이 없나요?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isSubmitting ? null : () => context.go('/register'),
                    child: Text(
                      '회원가입',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
