import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/login_models.dart';
import '../view_models/sign_up_view_model.dart';

import '../theme/app_colors.dart';
import '../utils/sign_up_validators.dart';
import '../widgets/login_prompt.dart';
import '../widgets/movielog_text_form_field.dart';
import '../widgets/sign_up_submit_button.dart';
import '../widgets/terms_agreement_tile.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();

  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = false;

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  /// 8주차: 실제 회원가입 요청 후 로그인 화면으로 이동합니다.
  Future<void> _submit() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();

    final viewModel = context.read<SignUpViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    await viewModel.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: passwordController.text,
        nickname: nicknameController.text,
      ),
    );
    if (!mounted) return;

    if (viewModel.status == SignUpStatus.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('회원가입이 완료됐어요. 로그인해 주세요.')),
      );
      context.go('/login');
    } else if (viewModel.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.watch<SignUpViewModel>().status == SignUpStatus.submitting;
    final canSubmit =
        SignUpValidators.nickname(nicknameController.text) == null &&
        SignUpValidators.email(emailController.text) == null &&
        SignUpValidators.password(passwordController.text) == null &&
        agreedToTerms;

    return PopScope(
      canPop: !isSubmitting, // 제출 중에는 화면을 나갈 수 없습니다.
      child: Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/login'),
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.violet,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxFormWidth = constraints.maxWidth >= 700
                ? 560.0
                : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.darkGray,
                          ),
                        ),

                        const SizedBox(height: 48),

                        MovieLogTextFormField(
                          label: '닉네임',
                          hintText: '닉네임을 입력해주세요',
                          controller: nicknameController,
                          validator: SignUpValidators.nickname,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) =>
                              emailFocusNode.requestFocus(),
                        ),

                        const SizedBox(height: 16),

                        MovieLogTextFormField(
                          label: '이메일',
                          hintText: '이메일 주소를 입력해주세요',
                          controller: emailController,
                          focusNode: emailFocusNode,
                          validator: SignUpValidators.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) =>
                              passwordFocusNode.requestFocus(),
                        ),

                        const SizedBox(height: 16),

                        MovieLogTextFormField(
                          label: '비밀번호',
                          hintText: '비밀번호를 입력해주세요',
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          validator: SignUpValidators.password,
                          textInputAction: TextInputAction.done,
                          isPassword: true,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                        ),

                        const SizedBox(height: 120),

                        TermsAgreementTile(
                          value: agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              agreedToTerms = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        SignUpSubmitButton(
                          enabled: canSubmit && !isSubmitting,
                          onPressed: _submit,
                        ),

                        const SizedBox(height: 24),

                        LoginPrompt(
                          onLoginTap: isSubmitting
                              ? null
                              : () => context.go('/login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
    );
  }
}
