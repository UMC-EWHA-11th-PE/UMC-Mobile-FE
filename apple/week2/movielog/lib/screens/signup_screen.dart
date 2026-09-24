import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';

/// 입력값을 검사해 오류 메시지를 돌려주는 함수 타입입니다. 통과하면 null입니다.
typedef FieldValidator = String? Function(String? value);

/// W2-01 회원가입 화면입니다. Figma 프레임 388 기준으로 배치합니다.
///
/// Guided Practice 구조:
/// - Step 1. Scaffold + SafeArea + SingleChildScrollView + Form(GlobalKey)
/// - Step 2. Controller / FocusNode / 약관 동의 bool / dispose
/// - Step 3. 닉네임 TextFormField (label, hint, 빈 값·2자 미만 검사, onChanged setState)
///
/// 화면은 의미 단위로 나뉩니다.
/// - [_WelcomeMessage] 환영 문구
/// - [_SignupFields] 닉네임·이메일·비밀번호 입력창 묶음
/// - [_SignupFooter] 약관 동의, 가입하기 버튼, 로그인 링크
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Step 1. Form 전체를 제어할 키
  final _formKey = GlobalKey<FormState>();

  // Step 2. 입력값을 읽고 지울 Controller
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Step 2. 이메일에서 "다음"을 누르면 비밀번호로 포커스를 옮기기 위한 FocusNode
  final _passwordFocusNode = FocusNode();

  // Step 2. 약관 동의 여부
  bool _agreedToTerms = false;

  @override
  void dispose() {
    // Step 2. State가 사라질 때 리소스를 반드시 해제합니다.
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validator — TextFormField와 버튼 활성화 판단에서 함께 사용합니다.
  // ---------------------------------------------------------------------------

  String? _validateNickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '닉네임을 입력해주세요.';
    if (text.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '이메일을 입력해주세요.';
    if (!_emailPattern.hasMatch(text)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return '비밀번호를 입력해주세요.';
    if (text.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  /// 세 입력이 모두 유효하고 약관에 동의했을 때만 가입하기 버튼을 켭니다.
  bool get _canSubmit =>
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _agreedToTerms;

  /// 가입하기 — Form 전체를 다시 검증한 뒤 통과했을 때만 진행합니다.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nicknameController.text.trim()}님, 환영합니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '회원가입'),
      body: SafeArea(
        // 키보드가 올라와도 입력창이 가려지지 않도록 스크롤 가능하게 만듭니다.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              // 내용이 짧아도 하단 영역이 화면 아래에 붙도록 최소 높이를 보장합니다.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                // 사용자가 입력을 시작한 필드부터 즉시 검사합니다. (W2-02)
                autovalidateMode: AutovalidateMode.onUserInteraction,
                // 메인 컨테이너: padding 24 / 16, gap 32
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  // Expanded를 스크롤 뷰 안에서 쓰기 위해 IntrinsicHeight로 높이를 확정합니다.
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _WelcomeMessage(),
                        const SizedBox(height: 32),
                        _SignupFields(
                          nicknameController: _nicknameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          passwordFocusNode: _passwordFocusNode,
                          validateNickname: _validateNickname,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                          // 입력이 바뀔 때마다 버튼 활성화와 상태 아이콘을 다시 계산합니다.
                          onChanged: () => setState(() {}),
                          onPasswordSubmitted: _canSubmit ? _submit : null,
                        ),
                        const SizedBox(height: 32),
                        // 하단 컨테이너(Fill)는 남은 공간을 채우고 내용은 아래에 붙입니다.
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _SignupFooter(
                              agreedToTerms: _agreedToTerms,
                              onAgreedChanged: (value) =>
                                  setState(() => _agreedToTerms = value),
                              onSubmit: _canSubmit ? _submit : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 환영합니다 — 356x64, padding-bottom 16, Manrope 500 16/24 #494551 center
class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
        textAlign: TextAlign.center,
        style: textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// 입력창 묶음 — 닉네임·이메일·비밀번호, gap 16
class _SignupFields extends StatelessWidget {
  const _SignupFields({
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.validateNickname,
    required this.validateEmail,
    required this.validatePassword,
    required this.onChanged,
    required this.onPasswordSubmitted,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final FieldValidator validateNickname;
  final FieldValidator validateEmail;
  final FieldValidator validatePassword;
  final VoidCallback onChanged;

  /// 비밀번호에서 키보드 완료를 눌렀을 때 실행합니다. null이면 아무 일도 하지 않습니다.
  final VoidCallback? onPasswordSubmitted;

  /// 비어 있으면 suffixIcon 자리를 아예 만들지 않습니다. (W2-01)
  Widget? _statusIcon(String value, FieldValidator validator) =>
      value.isEmpty ? null : _StatusIcon(value: value, validator: validator);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 3. 닉네임
        _LabeledField(
          label: '닉네임',
          child: TextFormField(
            controller: nicknameController,
            validator: validateNickname,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.next,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '닉네임을 입력해주세요',
              suffixIcon: _statusIcon(nicknameController.text, validateNickname),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 이메일
        _LabeledField(
          label: '이메일',
          child: TextFormField(
            controller: emailController,
            validator: validateEmail,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '이메일 주소를 입력해주세요',
              suffixIcon: _statusIcon(emailController.text, validateEmail),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 비밀번호
        _LabeledField(
          label: '비밀번호',
          child: TextFormField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            validator: validatePassword,
            onChanged: (_) => onChanged(),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onPasswordSubmitted?.call(),
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '비밀번호를 입력해주세요',
              suffixIcon: _statusIcon(passwordController.text, validatePassword),
            ),
          ),
        ),
      ],
    );
  }
}

/// 라벨(24px) + 입력창을 gap 4로 묶은 위젯입니다. (Figma: 356x70)
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// 입력 상태에 따라 오른쪽에 붙는 20x20 아이콘입니다.
/// 오류면 ! (W2-02), 통과하면 체크(W2-03)
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.value, required this.validator});

  final String value;
  final FieldValidator validator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError = validator(value) != null;

    return Padding(
      // 오른쪽 여백 16 (Figma padding-right)
      padding: const EdgeInsets.only(right: 16),
      // 공통 에셋 SVG를 쓰고 colorFilter로 상태 색을 입힙니다.
      child: SvgPicture.asset(
        hasError ? 'assets/icons/error.svg' : 'assets/icons/check_circle_filled.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          hasError ? colors.error : colors.primary,
          BlendMode.srcIn,
        ),
        semanticsLabel: hasError ? '입력 오류' : '입력 확인',
      ),
    );
  }
}

/// 하단 컨테이너 — 약관 동의, 가입하기 버튼, 로그인 링크
/// padding-top 32, padding-bottom 16, gap 24
class _SignupFooter extends StatelessWidget {
  const _SignupFooter({
    required this.agreedToTerms,
    required this.onAgreedChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedChanged;

  /// null이면 가입하기 버튼이 비활성 상태로 그려집니다.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        // 남은 공간을 채우지 않고 내용 높이만 차지해야 Align이 아래로 붙입니다.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 필수 약관 — 체크박스 26x26 + 텍스트(left 32)
          InkWell(
            onTap: () => onAgreedChanged(!agreedToTerms),
            borderRadius: BorderRadius.circular(AppTheme.checkboxRadius),
            child: Row(
              children: [
                SizedBox(
                  width: AppTheme.checkboxSize,
                  height: AppTheme.checkboxSize,
                  child: Checkbox(
                    value: agreedToTerms,
                    onChanged: (value) => onAgreedChanged(value ?? false),
                  ),
                ),
                const SizedBox(width: 32 - AppTheme.checkboxSize),
                Text('필수 약관에 동의합니다', style: textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 가입하기 — 356x72, padding-bottom 16, 내부 버튼 56
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: AppTheme.buttonHeight,
              child: ElevatedButton(
                onPressed: onSubmit,
                child: const Text('가입하기'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 이미 계정이 있나요? 로그인 — gap 4
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '이미 계정이 있나요?',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {}, // 2주차에는 로그인 화면 이동을 연결하지 않습니다.
                child: Text(
                  '로그인',
                  style: textTheme.titleMedium?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
