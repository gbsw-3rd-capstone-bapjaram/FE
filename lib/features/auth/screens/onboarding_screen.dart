import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  // 총 4스텝: 0=이메일/PW, 1=인증코드, 2=신체정보, 3=성별/활동량

  // Step 0
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  final _step0Form = GlobalKey<FormState>();

  // Step 1 — 인증 코드
  final _codeCtrl  = TextEditingController();
  int  _resendSecs = 0;

  // Step 2
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();
  String _goal = 'diet';
  final _step2Form = GlobalKey<FormState>();

  // Step 3
  String _gender   = 'male';
  String _activity = 'low';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _codeCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _next() async {
    final auth = ref.read(authProvider.notifier);

    if (_step == 0) {
      if (!(_step0Form.currentState?.validate() ?? false)) return;
      // 코드 발송
      final ok = await auth.sendVerification(_emailCtrl.text.trim());
      if (!ok || !mounted) return;
      setState(() { _startResendTimer(); });
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      final code = _codeCtrl.text.trim();
      if (code.length != 6) {
        ref.read(authProvider.notifier);
        // 직접 에러 표시
        return;
      }
      final ok = await auth.verifyEmail(_emailCtrl.text.trim(), code);
      if (!ok || !mounted) return;
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      if (!(_step2Form.currentState?.validate() ?? false)) return;
    }

    if (_step < 3) {
      setState(() => _step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prev(BuildContext context) {
    if (_step == 0) {
      context.go('/login');
    } else {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _startResendTimer() {
    setState(() => _resendSecs = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSecs--);
      return _resendSecs > 0;
    });
  }

  Future<void> _resendCode() async {
    if (_resendSecs > 0) return;
    _codeCtrl.clear();
    final ok = await ref.read(authProvider.notifier).sendVerification(_emailCtrl.text.trim());
    if (ok && mounted) _startResendTimer();
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider.notifier);
    final ok = await auth.signUp(_emailCtrl.text.trim(), _pwCtrl.text);
    if (!ok || !mounted) return;
    await auth.updateProfile({
      'height':         double.tryParse(_heightCtrl.text),
      'weight':         double.tryParse(_weightCtrl.text),
      'age':            int.tryParse(_ageCtrl.text),
      'gender':         _gender,
      'activity_level': _activity,
      'goal':           _goal,
    });
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 진행바 (4단계) ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? kPrimary : const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            // ── 페이지 콘텐츠 ────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step0(emailCtrl: _emailCtrl, pwCtrl: _pwCtrl, formKey: _step0Form),
                  _StepVerify(
                    email:      _emailCtrl.text,
                    codeCtrl:   _codeCtrl,
                    resendSecs: _resendSecs,
                    onResend:   _resendCode,
                  ),
                  _Step2(
                    heightCtrl: _heightCtrl,
                    weightCtrl: _weightCtrl,
                    ageCtrl: _ageCtrl,
                    goal: _goal,
                    onGoalChanged: (v) => setState(() => _goal = v),
                    formKey: _step2Form,
                  ),
                  _Step3(
                    gender:   _gender,
                    activity: _activity,
                    onGenderChanged:   (v) => setState(() => _gender = v),
                    onActivityChanged: (v) => setState(() => _activity = v),
                  ),
                ],
              ),
            ),
            // ── 하단 버튼 ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(auth.error!,
                          style: const TextStyle(color: kTextRed, fontSize: 13)),
                    ),
                  Row(
                    children: [
                      // 이전 / 로그인으로 버튼
                      SizedBox(
                        width: 100,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: auth.loading ? null : () => _prev(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimary,
                            side: const BorderSide(color: kPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(_step == 0 ? '로그인' : '이전'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 다음으로 버튼
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.loading ? null : _next,
                            child: auth.loading
                                ? const SizedBox(
                                    height: 22, width: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(_step == 3 ? '시작하기' : '다음으로'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 헤더 공통 ────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final String step, title, subtitle;
  const _StepHeader({required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step,
              style: const TextStyle(
                  color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, height: 1.25, color: Color(0xFF111111))),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: kTextGray, fontSize: 13, height: 1.4)),
        ],
      );
}

// ── STEP 01 — 이메일 / 비밀번호 ──────────────────────────────
class _Step0 extends StatelessWidget {
  final TextEditingController emailCtrl, pwCtrl;
  final GlobalKey<FormState> formKey;
  const _Step0({required this.emailCtrl, required this.pwCtrl, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(
              step:     'STEP 01',
              title:    '회원 정보를\n입력해 주세요',
              subtitle: '데이터 백업을 위해 필요해요',
            ),
            const SizedBox(height: 40),
            const AppFieldLabel('E - mail'),
            const SizedBox(height: 8),
            AppFocusField(
              ctrl:         emailCtrl,
              hint:         '---',
              keyboardType: TextInputType.emailAddress,
              validator:    (v) => (v == null || !v.contains('@')) ? '올바른 이메일을 입력해 주세요' : null,
            ),
            const SizedBox(height: 20),
            const AppFieldLabel('Password'),
            const SizedBox(height: 8),
            AppFocusField(
              ctrl:      pwCtrl,
              hint:      '---',
              obscure:   true,
              validator: (v) => (v == null || v.length < 6) ? '6자 이상 입력해 주세요' : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── STEP 02 — 이메일 인증 코드 ──────────────────────────────
class _StepVerify extends StatelessWidget {
  final String email;
  final TextEditingController codeCtrl;
  final int resendSecs;
  final VoidCallback onResend;
  const _StepVerify({
    required this.email,
    required this.codeCtrl,
    required this.resendSecs,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            step:     'STEP 02',
            title:    '이메일로 전송된\n코드를 입력해 주세요',
            subtitle: '인증 코드는 10분간 유효해요',
          ),
          const SizedBox(height: 12),
          // 발송 이메일 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.email_outlined, size: 16, color: kPrimary),
              const SizedBox(width: 8),
              Text(email,
                  style: const TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 32),
          const AppFieldLabel('인증 코드 6자리'),
          const SizedBox(height: 8),
          AppFocusField(
            ctrl:         codeCtrl,
            hint:         '------',
            keyboardType: TextInputType.number,
            maxLength:    6,
          ),
          const SizedBox(height: 20),
          // 재전송 버튼
          Center(
            child: GestureDetector(
              onTap: resendSecs > 0 ? null : onResend,
              child: RichText(
                text: TextSpan(children: [
                  const TextSpan(
                    text: '코드를 받지 못하셨나요?  ',
                    style: TextStyle(color: kTextGray, fontSize: 13),
                  ),
                  TextSpan(
                    text: resendSecs > 0 ? '재전송 (${resendSecs}s)' : '재전송',
                    style: TextStyle(
                      color: resendSecs > 0 ? kTextGray : kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── STEP 03 — 신체 정보 ──────────────────────────────────────
class _Step2 extends StatelessWidget {
  final TextEditingController heightCtrl, weightCtrl, ageCtrl;
  final String goal;
  final ValueChanged<String> onGoalChanged;
  final GlobalKey<FormState> formKey;
  const _Step2({
    required this.heightCtrl, required this.weightCtrl, required this.ageCtrl,
    required this.goal, required this.onGoalChanged, required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(
              step:     'STEP 03',
              title:    '내 신체 정보를\n입력해 주세요',
              subtitle: '정확한 급식 추천을 위해 필요해요',
            ),
            const SizedBox(height: 40),
            Row(children: [
              Expanded(child: _LabeledField(ctrl: heightCtrl, label: '키 (cm)',    hint: '---')),
              const SizedBox(width: 12),
              Expanded(child: _LabeledField(ctrl: weightCtrl, label: '몸무게 (kg)', hint: '---')),
            ]),
            const SizedBox(height: 20),
            _LabeledField(ctrl: ageCtrl, label: '나이', hint: '---'),
            const SizedBox(height: 28),
            const AppFieldLabel('목표'),
            const SizedBox(height: 10),
            Row(children: [
              _ChoiceBtn(label: '다이어트', value: 'diet',     selected: goal, onTap: onGoalChanged),
              const SizedBox(width: 8),
              _ChoiceBtn(label: '유지',     value: 'maintain', selected: goal, onTap: onGoalChanged),
              const SizedBox(width: 8),
              _ChoiceBtn(label: '증량',     value: 'bulk',     selected: goal, onTap: onGoalChanged),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── STEP 03 ──────────────────────────────────────────────────
class _Step3 extends StatelessWidget {
  final String gender, activity;
  final ValueChanged<String> onGenderChanged, onActivityChanged;
  const _Step3({
    required this.gender, required this.activity,
    required this.onGenderChanged, required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            step:     'STEP 04',
            title:    '상세 정보를\n입력해 주세요',
            subtitle: '보다 정확한 계산을 위해 필요해요',
          ),
          const SizedBox(height: 40),
          const AppFieldLabel('성별'),
          const SizedBox(height: 10),
          Row(children: [
            _ChoiceBtn(label: '남', value: 'male',   selected: gender, onTap: onGenderChanged),
            const SizedBox(width: 10),
            _ChoiceBtn(label: '여', value: 'female', selected: gender, onTap: onGenderChanged),
          ]),
          const SizedBox(height: 28),
          const AppFieldLabel('활동량'),
          const SizedBox(height: 10),
          Row(children: [
            _ChoiceBtn(label: '낮음', value: 'low',    selected: activity, onTap: onActivityChanged),
            const SizedBox(width: 8),
            _ChoiceBtn(label: '보통', value: 'medium', selected: activity, onTap: onActivityChanged),
            const SizedBox(width: 8),
            _ChoiceBtn(label: '높음', value: 'high',   selected: activity, onTap: onActivityChanged),
          ]),
        ],
      ),
    );
  }
}

// ── 내부 공통 위젯 ────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  const _LabeledField({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(label),
          const SizedBox(height: 8),
          AppFocusField(
            ctrl:         ctrl,
            hint:         hint,
            keyboardType: TextInputType.number,
            validator:    (v) => (v == null || v.isEmpty) ? '입력해 주세요' : null,
          ),
        ],
      );
}

class _ChoiceBtn extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _ChoiceBtn({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            color: active
                ? kPrimary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? kPrimary : const Color(0xFFDDDDDD),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:      active ? kPrimary : const Color(0xFFAAAAAA),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize:   15,
            ),
          ),
        ),
      ),
    );
  }
}
