import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';

/// W2-01 회원가입 화면입니다. Figma 프레임 388 기준으로 배치합니다.
///
/// Guided Practice 구조:
/// - Step 1. Scaffold + SafeArea + SingleChildScrollView + Form(GlobalKey)
/// - Step 2. Controller / FocusNode / 약관 동의 bool / dispose
/// - Step 3. 닉네임 TextFormField (label, hint, 빈 값·2자 미만 검사, onChanged setState)
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nicknameController.text.trim()}님, 환영합니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                        _buildWelcome(textTheme, colors),
                        const SizedBox(height: 32),
                        _buildInputs(textTheme, colors),
                        const SizedBox(height: 32),
                        // 하단 컨테이너(Fill)는 남은 공간을 채우고 내용은 아래에 붙입니다.
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildBottom(textTheme, colors),
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

  /// 환영합니다 — 356x64, padding-bottom 16, Manrope 500 16/24 #494551 center
  Widget _buildWelcome(TextTheme textTheme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
        textAlign: TextAlign.center,
        style: textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }

  /// 입력창 묶음 — gap 16
  Widget _buildInputs(TextTheme textTheme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 3. 닉네임
        _LabeledField(
          label: '닉네임',
          child: TextFormField(
            controller: _nicknameController,
            validator: _validateNickname,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '닉네임을 입력해주세요',
              suffixIcon: _statusIcon(
                _nicknameController.text,
                _validateNickname,
                colors,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 이메일
        _LabeledField(
          label: '이메일',
          child: TextFormField(
            controller: _emailController,
            validator: _validateEmail,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '이메일 주소를 입력해주세요',
              suffixIcon: _statusIcon(
                _emailController.text,
                _validateEmail,
                colors,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 비밀번호
        _LabeledField(
          label: '비밀번호',
          child: TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            validator: _validatePassword,
            onChanged: (_) => setState(() {}),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _canSubmit ? _submit() : null,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '비밀번호를 입력해주세요',
              suffixIcon: _statusIcon(
                _passwordController.text,
                _validatePassword,
                colors,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 입력 상태에 따라 오른쪽 아이콘을 바꿉니다.
  /// 비어 있으면 없음(W2-01), 오류면 ! (W2-02), 통과하면 체크(W2-03)
  Widget? _statusIcon(
    String value,
    String? Function(String?) validator,
    ColorScheme colors,
  ) {
    if (value.isEmpty) return null;
    final hasError = validator(value) != null;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Icon(
        hasError ? Icons.error_outline : Icons.check_circle,
        size: 20,
        color: hasError ? colors.error : colors.primary,
      ),
    );
  }

  /// 하단 컨테이너 — padding-top 32, padding-bottom 16, gap 24
  Widget _buildBottom(TextTheme textTheme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        // 남은 공간을 채우지 않고 내용 높이만 차지해야 Align이 아래로 붙입니다.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 필수 약관 — 체크박스 26x26 + 텍스트(left 32)
          InkWell(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            borderRadius: BorderRadius.circular(AppTheme.checkboxRadius),
            child: Row(
              children: [
                SizedBox(
                  width: AppTheme.checkboxSize,
                  height: AppTheme.checkboxSize,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
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
                onPressed: _canSubmit ? _submit : null,
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
