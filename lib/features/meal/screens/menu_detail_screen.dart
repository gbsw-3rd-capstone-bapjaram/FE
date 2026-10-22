import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_model.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../intake/providers/intake_provider.dart';

class MenuDetailScreen extends ConsumerStatefulWidget {
  final String focusMenu;
  final List<String> allMenus;
  final List<RecItem> recItems;
  final String date;
  final String mealType;

  const MenuDetailScreen({
    super.key,
    required this.focusMenu,
    required this.allMenus,
    required this.recItems,
    required this.date,
    required this.mealType,
  });

  @override
  ConsumerState<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends ConsumerState<MenuDetailScreen> {
  late Map<String, double> _ratios;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 각 메뉴 섭취 비율 초기화 (추천 비율로)
    final recMap = {for (final r in widget.recItems) r.menuName: r};
    _ratios = {
      for (final m in widget.allMenus)
        m: recMap[m]?.recommendedRatio ?? 1.0
    };
  }

  RecItem? get _focusRec =>
      widget.recItems.where((r) => r.menuName == widget.focusMenu).firstOrNull;

  Future<void> _saveIntake() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/intake', data: {
        'date':      widget.date,
        'meal_type': widget.mealType,
        'items': _ratios.entries.map((e) => {
          'menu_name':   e.key,
          'eaten_ratio': e.value,
        }).toList(),
      });
      // 저장 성공 → IntakeScreen 데이터 즉시 갱신
      ref.invalidate(dailyIntakeProvider(widget.date));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('섭취 기록이 저장됐어요 ✓'),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: kTextRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = _focusRec;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.focusMenu),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // ── 칼로리 히어로 카드 ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              const Text('예상 칼로리',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                rec != null ? '${rec.calories}' : '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text('kcal / 1인분',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              if (rec != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '• ${_goalBadgeText(rec)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // ── 영양소 뱃지 ─────────────────────────────────────
          if (rec != null)
            Row(children: [
              _NutriBadge(value: '${rec.protein.toStringAsFixed(0)}g', label: '단백질'),
              const SizedBox(width: 8),
              _NutriBadge(value: '${rec.carbs.toStringAsFixed(0)}g',   label: '탄수화물'),
              const SizedBox(width: 8),
              _NutriBadge(value: '${rec.fat.toStringAsFixed(0)}g',     label: '지방'),
              const SizedBox(width: 8),
              _NutriBadge(value: '${rec.sodium.toStringAsFixed(0)}mg', label: '나트륨'),
            ]),
          const SizedBox(height: 24),

          // ── 목표 기준 가이드 ────────────────────────────────
          const Text('목표 기준 가이드',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          const SizedBox(height: 10),
          if (rec != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                _GuideRow(
                  label: '상태',
                  value: _StatusBadge(status: rec.status),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _GuideRow(
                  label: '권장 섭취',
                  value: Text(
                    '${(rec.recommendedRatio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: kPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _GuideRow(
                  label: '이유',
                  value: Flexible(
                    child: Text(
                      rec.reason,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.4),
                    ),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 24),

          // ── 섭취 비율 ───────────────────────────────────────
          const Text('오늘 급식 섭취 비율',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: widget.allMenus.map((menu) {
                final ratio = _ratios[menu] ?? 1.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Row(children: [
                        SizedBox(
                          width: 80,
                          child: Text(menu,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                              activeTrackColor: ratio >= 0.7 ? kPrimary : kTextOrange,
                              inactiveTrackColor: const Color(0xFFEEEEEE),
                              thumbColor: ratio >= 0.7 ? kPrimary : kTextOrange,
                            ),
                            child: Slider(
                              value: ratio,
                              min: 0,
                              max: 1,
                              divisions: 10,
                              onChanged: (v) => setState(() => _ratios[menu] = v),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${(ratio * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ratio >= 0.7 ? kPrimary : kTextOrange,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      // ── 하단 버튼 ──────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: _saving ? null : _saveIntake,
            child: _saving
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('섭취 기록하기'),
          ),
        ),
      ),
    );
  }

  String _goalBadgeText(RecItem rec) {
    final status = ref.read(authProvider).user?.goal ?? 'maintain';
    return switch (status) {
      'diet' => '다이어트 목표에 적합',
      'bulk' => '증량 목표에 적합',
      _      => '유지 목표에 적합',
    };
  }
}

// ── 영양소 뱃지 ──────────────────────────────────────────────
class _NutriBadge extends StatelessWidget {
  final String value, label;
  const _NutriBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: kTextGray)),
          ]),
        ),
      );
}

// ── 가이드 행 ────────────────────────────────────────────────
class _GuideRow extends StatelessWidget {
  final String label;
  final Widget value;
  const _GuideRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: kTextGray, fontWeight: FontWeight.w500)),
          const Spacer(),
          value,
        ]),
      );
}

// ── 상태 뱃지 ────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'recommend' => ('추천 메뉴', kPrimaryLight, kPrimary),
      'moderate'  => ('적당히',    const Color(0xFFFFF3E0), kTextOrange),
      _           => ('일반',      const Color(0xFFF2F2F2), kTextGray),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
