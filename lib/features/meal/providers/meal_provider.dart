import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/meal_model.dart';
import '../models/recommendation_model.dart';

// ── 인메모리 급식 캐시 ────────────────────────────────────────
// key: "YYYY-MM-DD", value: 해당 날짜의 모든 meal 타입 리스트
final mealCacheProvider = StateProvider<Map<String, List<MealModel>>>(
  (ref) => {},
);

// ── 추천 캐시 ──────────────────────────────────────────────
// key: "YYYY-MM-DD_mealType"
final recCacheProvider = StateProvider<Map<String, List<RecItem>>>(
  (ref) => {},
);

// ── 섭취 기록 캐시 ────────────────────────────────────────
// key: "YYYY-MM-DD"
final intakeCacheProvider = StateProvider<Map<String, dynamic>>(
  (ref) => {},
);

// 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 선택된 식사 타입 (시간 기반 기본값)
final selectedMealTypeProvider = StateProvider<String>((ref) {
  final h = DateTime.now().hour;
  if (h < 10) return 'breakfast';
  if (h < 16) return 'lunch';
  return 'dinner';
});

// 일별 급식 — 캐시 우선, 없으면 API
final dailyMealsProvider =
    FutureProvider.autoDispose.family<List<MealModel>, String>((ref, date) async {
  final cache = ref.read(mealCacheProvider);
  if (cache.containsKey(date)) return cache[date]!;

  final dio = ref.read(dioProvider);
  final res = await dio.get('/meals/daily', queryParameters: {'date': date});
  final meals = res.data['data']['meals'] as List;
  return meals.map((e) => MealModel.fromJson(e)).toList();
});

// 추천 조회 — 캐시 우선
final recommendationProvider = FutureProvider.autoDispose
    .family<List<RecItem>, ({String date, String type})>((ref, args) async {
  final cacheKey = '${args.date}_${args.type}';
  final cache = ref.read(recCacheProvider);
  if (cache.containsKey(cacheKey)) return cache[cacheKey]!;

  final dio = ref.read(dioProvider);
  final res = await dio.get('/recommendation',
      queryParameters: {'date': args.date, 'type': args.type});
  final items = (res.data['data']['items'] as List)
      .map((e) => RecItem.fromJson(e))
      .toList();

  // 캐시에 저장
  ref.read(recCacheProvider.notifier).update((s) => {...s, cacheKey: items});
  return items;
});
