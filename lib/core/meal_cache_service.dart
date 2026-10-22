import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/meal/models/meal_model.dart';

/// 월별 급식 데이터를 SharedPreferences에 저장/불러오기
class MealCacheService {
  static const _prefix = 'meal_cache_';

  static String _key(int year, int month) =>
      '$_prefix${year}_${month.toString().padLeft(2, '0')}';

  /// 캐시 저장 (date → List<MealModel>)
  static Future<void> saveMonth(
      int year, int month, Map<String, List<MealModel>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(data.map(
      (date, meals) => MapEntry(date, meals.map((m) => m.toJson()).toList()),
    ));
    await prefs.setString(_key(year, month), encoded);
  }

  /// 캐시 불러오기 (없으면 null)
  static Future<Map<String, List<MealModel>>?> loadMonth(
      int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(year, month));
    if (raw == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((date, meals) => MapEntry(
            date,
            (meals as List)
                .map((m) => MealModel.fromJson(m as Map<String, dynamic>))
                .toList(),
          ));
    } catch (_) {
      return null; // 파싱 실패 시 null → 재패치
    }
  }

  /// 특정 월 캐시 삭제
  static Future<void> clearMonth(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(year, month));
  }
}
