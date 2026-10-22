import 'package:flutter/material.dart';
import 'theme.dart';

/// 포커스 시 teal 배경 + teal 테두리로 변경되는 공통 입력 필드
class AppFocusField extends StatefulWidget {
  final TextEditingController ctrl;
  final String? hint;
  final bool obscure;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final int? maxLength;

  const AppFocusField({
    super.key,
    required this.ctrl,
    this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLength,
  });

  @override
  State<AppFocusField> createState() => _AppFocusFieldState();
}

class _AppFocusFieldState extends State<AppFocusField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   widget.ctrl,
      focusNode:    _focus,
      obscureText:  widget.obscure,
      keyboardType: widget.keyboardType,
      maxLength:    widget.maxLength,
      buildCounter: widget.maxLength != null ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111111)),
      decoration: InputDecoration(
        hintText:  widget.hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
        filled:    true,
        fillColor: _focused ? kPrimaryLight : const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kTextRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kTextRed, width: 1.5),
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// 공통 필드 라벨
class AppFieldLabel extends StatelessWidget {
  final String text;
  const AppFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      );
}

/// shimmer 효과 없는 단순 스켈레톤 박스
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// 급식 메뉴 리스트 스켈레톤
class MealListSkeleton extends StatelessWidget {
  const MealListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: List.generate(4, (i) => Column(
          children: [
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 14),
                        const SizedBox(height: 8),
                        SkeletonBox(width: 80, height: 11),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 44, height: 24, radius: 20),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}

/// 요약 카드 스켈레톤
class SummaryCardSkeleton extends StatelessWidget {
  const SummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 80, height: 11),
                const SizedBox(height: 8),
                SkeletonBox(width: 120, height: 28),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBox(width: 40, height: 11),
              const SizedBox(height: 8),
              SkeletonBox(width: 60, height: 28),
            ],
          ),
        ],
      ),
    );
  }
}
