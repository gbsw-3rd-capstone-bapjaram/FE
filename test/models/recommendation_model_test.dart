import 'package:flutter_test/flutter_test.dart';
import 'package:bapjaram/features/meal/models/recommendation_model.dart';

Map<String, dynamic> baseJson({
  String status = 'normal',
  double sodium = 100,
  double protein = 5,
  double carbs = 10,
  double recommendedRatio = 1.0,
}) =>
    {
      'menu_name': '테스트메뉴',
      'calories': 300,
      'protein': protein,
      'carbs': carbs,
      'fat': 8.0,
      'fiber': 2.0,
      'sodium': sodium,
      'status': status,
      'recommended_ratio': recommendedRatio,
      'reason': '테스트 이유',
    };

void main() {
  group('RecItem.fromJson', () {
    test('모든 필드 파싱', () {
      final item = RecItem.fromJson(baseJson());

      expect(item.menuName, '테스트메뉴');
      expect(item.calories, 300);
      expect(item.protein, 5.0);
      expect(item.carbs, 10.0);
      expect(item.fat, 8.0);
      expect(item.fiber, 2.0);
      expect(item.sodium, 100.0);
      expect(item.status, 'normal');
      expect(item.recommendedRatio, 1.0);
      expect(item.reason, '테스트 이유');
    });

    test('status 누락 시 normal 기본값', () {
      final json = Map<String, dynamic>.from(baseJson())..remove('status');
      final item = RecItem.fromJson(json);
      expect(item.status, 'normal');
    });

    test('reason 누락 시 빈 문자열', () {
      final json = Map<String, dynamic>.from(baseJson())..remove('reason');
      final item = RecItem.fromJson(json);
      expect(item.reason, '');
    });

    test('calories int → int 변환', () {
      final json = baseJson()..['calories'] = 250;
      final item = RecItem.fromJson(json);
      expect(item.calories, 250);
    });
  });

  group('RecItem.statusLabel', () {
    test('상태 레이블', () {
      expect(RecItem.fromJson(baseJson(status: 'recommend')).statusLabel, '추천');
      expect(RecItem.fromJson(baseJson(status: 'moderate')).statusLabel, '적당히');
      expect(RecItem.fromJson(baseJson(status: 'normal')).statusLabel, '일반');
      expect(RecItem.fromJson(baseJson(status: 'unknown')).statusLabel, '일반');
    });
  });

  group('RecItem.nutrientHint', () {
    test('나트륨 500 이상 → 나트륨 주의', () {
      final item = RecItem.fromJson(baseJson(sodium: 500));
      expect(item.nutrientHint, '나트륨 주의');
    });

    test('나트륨 499 + 단백질 15 이상 → 단백질 표시', () {
      final item = RecItem.fromJson(baseJson(sodium: 499, protein: 15));
      expect(item.nutrientHint, contains('단백질'));
    });

    test('나트륨 499 + 단백질 14 + 탄수화물 30 이상 → 탄수화물 표시', () {
      final item = RecItem.fromJson(baseJson(sodium: 100, protein: 5, carbs: 30));
      expect(item.nutrientHint, contains('탄수화물'));
    });

    test('모두 낮으면 빈 문자열', () {
      final item = RecItem.fromJson(baseJson(sodium: 100, protein: 5, carbs: 10));
      expect(item.nutrientHint, '');
    });

    test('나트륨이 정확히 500일 때 나트륨 주의', () {
      final item = RecItem.fromJson(baseJson(sodium: 500));
      expect(item.nutrientHint, '나트륨 주의');
    });
  });
}
