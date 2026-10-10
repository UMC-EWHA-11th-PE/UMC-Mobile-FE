import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final nicknameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  final formKey = GlobalKey<FormState>();

  bool agreedToTerms = false;

  // 이메일 형식 검사
  bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // 닉네임 유효성 검사
  bool get isNicknameValid {
    return nicknameController.text.trim().length >= 2;
  }

  // 이메일 유효성 검사
  bool get isEmailValid {
    return isValidEmail(emailController.text.trim());
  }

  // 비밀번호 유효성 검사
  bool get isPasswordValid {
    return passwordController.text.length >= 8;
  }

  // 닉네임에 입력값이 있는지 확인
  bool get hasNicknameInput {
    return nicknameController.text.trim().isNotEmpty;
  }

  // 이메일에 입력값이 있는지 확인
  bool get hasEmailInput {
    return emailController.text.trim().isNotEmpty;
  }

  // 비밀번호에 입력값이 있는지 확인
  bool get hasPasswordInput {
    return passwordController.text.isNotEmpty;
  }

  //약관 동의 확인
  bool get isFormValid {
    return isNicknameValid && isEmailValid && isPasswordValid && agreedToTerms;
  }

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    nicknameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 뒤로가기 + 회원가입
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.go('/start');
                      },
                      icon: const Icon(Icons.arrow_back, size: 28),
                    ),
                    const Expanded(
                      child: Text(
                        '회원가입',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D50B4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 60),

                // 안내 문구
                const Text(
                  '환영합니다!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 6),

                const Text(
                  '간단한 정보만 입력하고 시작해보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
                ),

                const SizedBox(height: 60),

                // =========================
                // 닉네임
                // =========================
                const Text(
                  '닉네임',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: nicknameController,
                  focusNode: nicknameFocusNode,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,

                  decoration: InputDecoration(
                    hintText: '닉네임을 입력해주세요',

                    // 정상 → 보라색 체크
                    // 오류 → 빨간 error.svg
                    // 입력 전 → 아이콘 없음
                    suffixIcon: isNicknameValid
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF6D50B4),
                          )
                        : hasNicknameInput
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              'assets/icons/error.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        : null,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD0CCD4)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF6D50B4),
                        width: 1.5,
                      ),
                    ),

                    // 오류일 때 빨간 테두리
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),

                    // 오류 상태에서 입력 중일 때도 빨간 테두리
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (value) {
                    final nickname = value?.trim() ?? '';

                    if (nickname.isEmpty) {
                      return '닉네임을 입력해주세요.';
                    }

                    if (nickname.length < 2) {
                      return '닉네임은 2자 이상이어야 합니다.';
                    }

                    return null;
                  },

                  onChanged: (_) {
                    setState(() {});
                  },

                  onFieldSubmitted: (_) {
                    emailFocusNode.requestFocus();
                  },
                ),

                const SizedBox(height: 28),

                // =========================
                // 이메일
                // =========================
                const Text(
                  '이메일',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: emailController,
                  focusNode: emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,

                  decoration: InputDecoration(
                    hintText: '이메일 주소를 입력해주세요',

                    // 정상 → 보라색 체크
                    // 오류 → 빨간 error.svg
                    suffixIcon: isEmailValid
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF6D50B4),
                          )
                        : hasEmailInput
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              'assets/icons/error.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        : null,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD0CCD4)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF6D50B4),
                        width: 1.5,
                      ),
                    ),

                    // 오류일 때 빨간 테두리
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return '이메일을 입력해주세요.';
                    }

                    if (!isValidEmail(email)) {
                      return '올바른 이메일 형식이 아닙니다.';
                    }

                    return null;
                  },

                  onChanged: (_) {
                    setState(() {});
                  },

                  onFieldSubmitted: (_) {
                    passwordFocusNode.requestFocus();
                  },
                ),

                const SizedBox(height: 28),

                // =========================
                // 비밀번호
                // =========================
                const Text(
                  '비밀번호',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,

                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력해주세요',

                    // 정상 → 보라색 체크
                    // 오류 → 빨간 error.svg
                    suffixIcon: isPasswordValid
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF6D50B4),
                          )
                        : hasPasswordInput
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              'assets/icons/error.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        : null,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD0CCD4)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF6D50B4),
                        width: 1.5,
                      ),
                    ),

                    // 오류일 때 빨간 테두리
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (value) {
                    final password = value ?? '';

                    if (password.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }

                    if (password.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다.';
                    }

                    return null;
                  },

                  onChanged: (_) {
                    setState(() {});
                  },

                  onFieldSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 180),

                Row(
                  children: [
                    Checkbox(
                      value: agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          agreedToTerms = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF6D50B4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      '필수 약관에 동의합니다',
                      style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isFormValid
                        ? () {
                            final isValid =
                                formKey.currentState?.validate() ?? false;

                            if (isValid) {
                              FocusScope.of(context).unfocus();

                              context.go('/home');
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D50B4),
                      disabledBackgroundColor: const Color(0xFFD1C5E2),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '가입하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 38),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '이미 계정이 있나요? ',
                      style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 이후 로그인 화면으로 이동
                      },
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D50B4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
