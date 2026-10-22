import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/intake_provider.dart';
import '../models/intake_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme.dart';

class IntakeScreen extends ConsumerWidget {
  const IntakeScreen({super.key});

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(intakeDateProvider);
    final dateStr = _fmt(date);
    final intake = ref.watch(dailyIntakeProvider(dateStr));
    final user = ref.watch(authProvider).user;
    final dailyTarget = user?.dailyCalories ?? 2000;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            onPressed: () => _pickDate(context, ref, date),
          ),
        ],
      ),
      body: intake.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => const Center(child: Text('기록이 없어요', style: TextStyle(color: kTextGray))),
        data: (data) => _Body(data: data, dailyTarget: dailyTarget),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2026, 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (picked != null) ref.read(intakeDateProvider.notifier).state = picked;
  }
}

class _Body extends StatelessWidget {
  final DailyIntake data;
  final double dailyTarget;
  const _Body({required this.data, required this.dailyTarget});

  @override
  Widget build(BuildContext context) {
    final progress = (dailyTarget > 0 ? (data.totalCalories / dailyTarget).clamp(0.0, 1.0) : 0.0);
    final pct = (progress * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // 원형 칼로리 차트
        Center(
          child: CircularPercentIndicator(
            radius: 90,
            lineWidth: 14,
            percent: progress,
            progressColor: kPrimary,
            backgroundColor: const Color(0xFFE0E0E0),
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.totalCalories.toInt().toString(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextDark),
                ),
                Text(
                  '/ ${dailyTarget.toInt()} kcal',
                  style: const TextStyle(fontSize: 13, color: kTextGray),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '목표 대비 $pct% 달성',
            style: const TextStyle(color: kTextGray, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        // 단백질 / 탄수화물 / 지방
        Row(children: [
          _NutriBadge(label: '단백질', value: data.totalProtein, color: kPrimary),
          const SizedBox(width: 12),
          _NutriBadge(label: '탄수화물', value: data.totalCarbs, color: kTextOrange),
          const SizedBox(width: 12),
          _NutriBadge(label: '지방', value: data.totalFat, color: kTextRed),
        ]),
        const SizedBox(height: 28),
        const Text('오늘 섭취 기록', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (data.meals.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text('아직 기록된 섭취 내역이 없어요', style: TextStyle(color: kTextGray)),
            ),
          )
        else
          ...data.meals.expand((meal) => [
            // ── 끼니 헤더 ──────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      meal.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${meal.items.length}가지',
                    style: const TextStyle(fontSize: 12, color: kTextGray),
                  ),
                ],
              ),
            ),
            // ── 해당 끼니 메뉴 카드들 ──────────────────
            ...meal.items.map((it) => _IntakeCard(item: it)),
            const SizedBox(height: 8),
          ]),
      ],
    );
  }
}

class _NutriBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _NutriBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}g',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: kTextGray)),
            ],
          ),
        ),
      );
}

class _IntakeCard extends StatelessWidget {
  final IntakeDetail item;
  const _IntakeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final pct = (item.eatenRatio * 100).round();
    final color = pct >= 80 ? kPrimary : pct >= 50 ? kTextOrange : kTextGray;

    // 주요 영양소 표시
    final details = <String>[];
    if (item.protein > 0) details.add('단백질 ${item.protein.toStringAsFixed(0)}g');
    if (item.carbs > 0) details.add('탄수 ${item.carbs.toStringAsFixed(0)}g');
    if (item.sodium > 0 && details.length < 2) details.add('나트륨 ${item.sodium.toStringAsFixed(0)}mg');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(item.menuName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                ]),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details.join(' · '), style: const TextStyle(fontSize: 12, color: kTextGray)),
                ],
              ],
            ),
          ),
          Text(
            '${item.calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
