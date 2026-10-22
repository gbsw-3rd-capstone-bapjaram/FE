import 'package:flutter_test/flutter_test.dart';
import 'package:bapjaram/features/meal/models/meal_model.dart';

void main() {
  group('MealMenu', () {
    test('fromJson', () {
      final m = MealMenu.fromJson({'id': 1, 'menu_name': '나물비빔밥'});
      expect(m.id, 1);
      expect(m.menuName, '나물비빔밥');
    });

    test('toJson', () {
      const m = MealMenu(id: 2, menuName: '청국장찌개');
      expect(m.toJson(), {'id': 2, 'menu_name': '청국장찌개'});
    });
  });

  group('MealModel.fromJson', () {
    test('모든 필드 파싱', () {
      final json = {
        'id': 10,
        'meal_date': '2026-06-09',
        'meal_type': 'lunch',
        'menus': [
          {'id': 1, 'menu_name': '밥'},
          {'id': 2, 'menu_name': '국'},
        ],
        'cal_info': '650.8 Kcal',
      };
      final meal = MealModel.fromJson(json);

      expect(meal.id, 10);
      expect(meal.mealDate, '2026-06-09');
      expect(meal.mealType, 'lunch');
      expect(meal.menus.length, 2);
      expect(meal.menus[0].menuName, '밥');
      expect(meal.calInfo, '650.8 Kcal');
    });

    test('menus 없을 때 빈 리스트', () {
      final json = {
        'id': 1,
        'meal_date': '2026-06-09',
        'meal_type': 'breakfast',
        'menus': null,
      };
      final meal = MealModel.fromJson(json);
      expect(meal.menus, isEmpty);
    });

    test('meal_date 누락 시 빈 문자열', () {
      final json = {
        'id': 1,
        'meal_type': 'dinner',
        'menus': [],
      };
      final meal = MealModel.fromJson(json);
      expect(meal.mealDate, '');
    });
  });

  group('MealModel.toJson', () {
    test('직렬화 후 역직렬화 동일', () {
      final original = MealModel(
        id: 5,
        mealDate: '2026-06-09',
        mealType: 'dinner',
        menus: [const MealMenu(id: 1, menuName: '김치')],
        calInfo: '500 Kcal',
      );
      final json = original.toJson();
      final restored = MealModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.mealDate, original.mealDate);
      expect(restored.mealType, original.mealType);
      expect(restored.menus.length, 1);
      expect(restored.menus[0].menuName, '김치');
      expect(restored.calInfo, original.calInfo);
    });
  });

  group('MealModel.mealTypeLabel', () {
    test('타입 레이블 변환', () {
      MealModel make(String t) => MealModel(id: 1, mealDate: '', mealType: t, menus: const []);

      expect(make('breakfast').mealTypeLabel, '조식');
      expect(make('lunch').mealTypeLabel, '중식');
      expect(make('dinner').mealTypeLabel, '석식');
      expect(make('unknown').mealTypeLabel, '중식'); // 기본값
    });
  });
}
