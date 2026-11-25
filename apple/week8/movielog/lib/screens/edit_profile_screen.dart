import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/labeled_input.dart';
import '../widgets/movielog_button.dart';

/// 프로필 수정 화면 (W8-07 기본 · W8-08 저장 중 · W8-09 닉네임 중복 오류)
///
/// - 성공: AuthViewModel.member가 이미 교체됨 → Snackbar → 마이페이지로 pop
/// - 입력·중복 오류: 화면에 남아 닉네임 아래 문구, 입력값 유지
/// - 401 세션 만료: 세션 정리 → Router가 /login으로 이동 (pop하지 않음)
/// - 네트워크 오류: Snackbar, 로그아웃하지 않고 다시 저장 가능
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const int maxNicknameLength = 12;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _nicknameController = TextEditingController(text: member?.nickname ?? '');
    _emailController = TextEditingController(text: member?.email ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    FocusScope.of(context).unfocus();

    final success = await viewModel.save(_nicknameController.text);
    if (!mounted) return;

    if (success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('프로필을 수정했어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      // 지금 화면의 PopScope는 아직 '저장 중(canPop: false)'으로 그려져 있어 바로 pop하면 막힙니다.
      // 저장 완료 상태로 다시 그려진 다음 프레임 뒤에 돌아갑니다.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      router.pop(); // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있습니다.
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(viewModel.message!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.isSaving;
        final nicknameError = viewModel.nicknameError;

        // 저장 중에는 요청 결과를 반영하지 못한 채 사라지지 않도록 뒤로가기를 막습니다.
        return PopScope(
          canPop: !saving,
          child: Scaffold(
            appBar: const CommonAppBar(
              title: '프로필 수정',
              titleStyle: AppTheme.appBarTitleBold,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledInput(
                      label: '이메일 (변경할 수 없습니다)',
                      child: TextField(
                        controller: _emailController,
                        enabled: false, // 이메일은 읽기 전용입니다.
                        style: movieLogInputTextStyle(context)
                            ?.copyWith(color: colors.onSurfaceVariant),
                        // 비활성 입력창의 기본 테두리(회색) 대신 다른 입력창과 같은 테두리를 씁니다.
                        decoration:
                            movieLogInputDecoration(
                              context,
                              fillColor: AppColors.inputReadOnlyBackground,
                            ).copyWith(
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    LabeledInput(
                      label: '닉네임',
                      child: TextField(
                        controller: _nicknameController,
                        // 저장 중에는 보낸 값과 화면 값이 달라지지 않게 입력을 막습니다.
                        readOnly: saving,
                        onChanged: (_) {
                          viewModel.clearNicknameError();
                          setState(() {}); // 글자 수 갱신
                        },
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            EditProfileScreen.maxNicknameLength,
                          ),
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: movieLogInputTextStyle(context),
                        decoration: movieLogInputDecoration(
                          context,
                          hint: '닉네임을 입력해 주세요',
                          hasError: nicknameError != null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 오류 문구(왼쪽) + 글자 수(오른쪽) — 입력창 양 끝에 맞춥니다. (W8-09)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            nicknameError ?? '',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: colors.error,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_nicknameController.text.characters.length} / '
                          '${EditProfileScreen.maxNicknameLength}',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 저장 중: 회색 배경 + 로딩 표시 (W8-08)
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
