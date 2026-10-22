import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  final _form      = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _pwCtrl.text,
        );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                // ── 로고 ───────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.rice_bowl_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '밥자람',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // ── 타이틀 ─────────────────────────────────────
                const Text(
                  '로그인',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111111)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '경북소마고 학생 전용 서비스예요',
                  style: TextStyle(color: kTextGray, fontSize: 13),
                ),
                const SizedBox(height: 40),
                // ── 이메일 ─────────────────────────────────────
                const AppFieldLabel('E - mail'),
                const SizedBox(height: 8),
                AppFocusField(
                  ctrl:         _emailCtrl,
                  hint:         '---',
                  keyboardType: TextInputType.emailAddress,
                  validator:    (v) => (v == null || !v.contains('@')) ? '올바른 이메일을 입력해 주세요' : null,
                ),
                const SizedBox(height: 20),
                // ── 비밀번호 ────────────────────────────────────
                const AppFieldLabel('Password'),
                const SizedBox(height: 8),
                AppFocusField(
                  ctrl:      _pwCtrl,
                  hint:      '---',
                  obscure:   true,
                  validator: (v) => (v == null || v.length < 6) ? '6자 이상 입력해 주세요' : null,
                ),
                // ── 에러 ───────────────────────────────────────
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.error!, style: const TextStyle(color: kTextRed, fontSize: 13)),
                ],
                const SizedBox(height: 32),
                // ── 로그인 버튼 ────────────────────────────────
                ElevatedButton(
                  onPressed: auth.loading ? null : _login,
                  child: auth.loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('로그인'),
                ),
                const SizedBox(height: 20),
                // ── 회원가입 링크 ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('아직 계정이 없나요?',
                        style: TextStyle(color: kTextGray, fontSize: 13)),
                    TextButton(
                      onPressed: () => context.go('/onboarding'),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('회원가입',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
