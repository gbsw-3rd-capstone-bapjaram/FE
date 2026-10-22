import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal_model.dart';
import '../models/recommendation_model.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import 'menu_detail_screen.dart';

class MealScreen extends ConsumerWidget {
  const MealScreen({super.key});

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _headerDate(DateTime d) {
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')} ${wd[d.weekday - 1]}요일';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date        = ref.watch(selectedDateProvider);
    final dateStr     = _fmt(date);
    final mealType    = ref.watch(selectedMealTypeProvider);
    final dailyAsync  = ref.watch(dailyMealsProvider(dateStr));
    final recAsync    = ref.watch(recommendationProvider((date: dateStr, type: mealType)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 날짜 헤더 ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_headerDate(date),
                      style: const TextStyle(fontSize: 12, color: kTextGray)),
                  const SizedBox(height: 4),
                  const Text('오늘의 급식',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                ],
              ),
            ),
            // ── 주간 날짜 스트립 ────────────────────────────────
            _WeekStrip(selected: date, onTap: (d) {
              ref.read(selectedDateProvider.notifier).state = d;
            }),
            const SizedBox(height: 16),
            Expanded(
              child: dailyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
                error:   (e, _) => Center(child: Text('불러오기 실패\n$e', textAlign: TextAlign.center, style: const TextStyle(color: kTextGray))),
                data: (meals) {
                  // 선택된 meal type 자동 보정
                  final types = meals.map((m) => m.mealType).toList();
                  final currentType = types.contains(mealType) ? mealType : (types.isNotEmpty ? types.first : mealType);
                  if (currentType != mealType) {
                    Future.microtask(() => ref.read(selectedMealTypeProvider.notifier).state = currentType);
                  }
                  final meal = meals.where((m) => m.mealType == currentType).firstOrNull;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      // ── 식사 타입 탭 ──────────────────────────
                      _MealTypeTabs(
                        types: types,
                        selected: currentType,
                        onTap: (t) => ref.read(selectedMealTypeProvider.notifier).state = t,
                      ),
                      const SizedBox(height: 14),
                      // ── 요약 카드 ─────────────────────────────
                      if (meal != null)
                        _SummaryCard(meal: meal, recAsync: recAsync),
                      const SizedBox(height: 20),
                      // ── 메뉴 리스트 ───────────────────────────
                      if (meal != null) ...[
                        const Text('메뉴 & 섭취 가이드',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                        const SizedBox(height: 10),
                        _MenuList(meal: meal, recAsync: recAsync, date: dateStr),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.no_meals_outlined, size: 48, color: kTextGray),
                              SizedBox(height: 12),
                              Text('급식 정보가 없어요', style: TextStyle(color: kTextGray)),
                            ]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 주간 스트립 ──────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onTap;
  const _WeekStrip({required this.selected, required this.onTap});

  static const _wd = ['월', '화', '수', '목', '금'];

  @override
  Widget build(BuildContext context) {
    // 이번 주 월요일
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    final days = List.generate(5, (i) => monday.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: days.map((d) {
          final isSelected = d.year == selected.year &&
              d.month == selected.month && d.day == selected.day;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 62,
                decoration: BoxDecoration(
                  color:        isSelected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? kPrimary : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_wd[d.weekday - 1],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white70 : kTextGray,
                        )),
                    const SizedBox(height: 4),
                    Text('${d.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF222222),
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 식사 타입 탭 ─────────────────────────────────────────────
class _MealTypeTabs extends StatelessWidget {
  final List<String> types;
  final String selected;
  final ValueChanged<String> onTap;
  const _MealTypeTabs({required this.types, required this.selected, required this.onTap});

  static const _all   = ['breakfast', 'lunch', 'dinner'];
  static const _label = {'breakfast': '조식', 'lunch': '중식', 'dinner': '석식'};

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _all.map((t) {
        final available = types.contains(t);
        final active    = t == selected && available;
        return Expanded(
          child: GestureDetector(
            onTap: available ? () => onTap(t) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color:        active ? kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? kPrimary : const Color(0xFFDDDDDD),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(_label[t]!,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color:      active ? Colors.white : (available ? kTextGray : const Color(0xFFCCCCCC)),
                  )),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 요약 카드 ────────────────────────────────────────────────
class _SummaryCard extends ConsumerWidget {
  final MealModel meal;
  final AsyncValue<List<RecItem>> recAsync;
  const _SummaryCard({required this.meal, required this.recAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recAsync.isLoading) return const SummaryCardSkeleton();

    // 유저의 하루 목표 칼로리 (프로필 고정값) — 끼니별로 달라지면 안 됨
    final dailyCal = ref.watch(authProvider).user?.dailyCalories;
    final calStr = dailyCal != null && dailyCal > 0
        ? dailyCal.toInt().toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
        : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color:        kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('하루 목표 칼로리',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                RichText(text: TextSpan(children: [
                  TextSpan(
                    text: '$calStr ',
                    style: const TextStyle(
                      fontFamily: 'Paperlogy',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(
                    text: 'kcal',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(meal.mealTypeLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              RichText(text: TextSpan(children: [
                TextSpan(
                  text: '${meal.menus.length}',
                  style: const TextStyle(
                    fontFamily: 'Paperlogy',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: '가지',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ])),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 메뉴 리스트 ──────────────────────────────────────────────
class _MenuList extends StatelessWidget {
  final MealModel meal;
  final AsyncValue<List<RecItem>> recAsync;
  final String date;
  const _MenuList({required this.meal, required this.recAsync, required this.date});

  @override
  Widget build(BuildContext context) {
    if (recAsync.isLoading) return const MealListSkeleton();

    final recMap = {
      for (final r in (recAsync.valueOrNull ?? [])) r.menuName: r
    };

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: meal.menus.asMap().entries.map((entry) {
          final idx  = entry.key;
          final menu = entry.value;
          final rec  = recMap[menu.menuName];

          return Column(
            children: [
              if (idx > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              InkWell(
                borderRadius: idx == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : idx == meal.menus.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : BorderRadius.zero,
                onTap: rec == null ? null : () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MenuDetailScreen(
                      focusMenu: menu.menuName,
                      allMenus:  meal.menus.map((m) => m.menuName).toList(),
                      recItems:  recAsync.valueOrNull ?? [],
                      date:      date,
                      mealType:  meal.mealType,
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(menu.menuName,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                            const SizedBox(height: 4),
                            Text(
                              rec != null
                                  ? '${rec.calories} kcal${rec.nutrientHint.isNotEmpty ? ' · ${rec.nutrientHint}' : ''}'
                                  : '',
                              style: const TextStyle(fontSize: 12, color: kTextGray),
                            ),
                          ],
                        ),
                      ),
                      if (rec != null) _StatusBadge(status: rec.status),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── 상태 뱃지 ────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'recommend' => ('추천',  kPrimaryLight,            kPrimary),
      'moderate'  => ('적당히', const Color(0xFFFFF3E0), kTextOrange),
      _           => ('일반',  const Color(0xFFF2F2F2),  kTextGray),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
